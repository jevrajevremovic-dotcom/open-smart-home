import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../devices/domain/smart_home_device.dart';

/// Home Assistant's AI Task (`ai_task.generate_data`, HA 2025.8+): the AI
/// the user set up in HA (OpenAI, Google, Anthropic, Ollama…). The app
/// has no AI of its own.
const aiTaskDomain = 'ai_task';
const aiTaskService = 'generate_data';

/// The most entities listed for the AI (a big home is cut, the rest named
/// by count only).
const aiMaxEntities = 400;

/// Actions that unlock, disarm or open: allowed, but called out in the
/// review so nobody saves one by mistake.
const sensitiveActions = {
  'lock.unlock',
  'lock.open',
  'alarm_control_panel.alarm_disarm',
  'cover.open_cover',
  'valve.open_valve',
};

/// Never saved from an AI draft: they run code, restart HA or reach other
/// servers. Such an automation can still be written in HA itself.
const blockedDomains = {
  'shell_command',
  'python_script',
  'pyscript',
  'rest_command',
  'hassio',
  'homeassistant',
  'recorder',
  'system_log',
};

/// What the AI is told: the format (documented automation syntax, JSON)
/// and the home's entities, by id and name. Nothing else is sent.
String aiAutomationInstructions(
  String request,
  Iterable<SmartHomeDevice> devices, {
  required String language,
}) {
  final list = devices.where((d) => !d.isAuxiliary).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final shown = list.take(aiMaxEntities);
  final b = StringBuffer()
    ..writeln(
      'Write one Home Assistant automation for this request, '
      'written by the user in language "$language":',
    )
    ..writeln(request.trim())
    ..writeln()
    ..writeln(
      'Answer with JSON only (no Markdown, no comments): an object with '
      '"alias" (short name in the language of the request), "description" '
      '(one sentence in that language saying what it does), "mode" '
      '("single", "restart", "queued" or "parallel"), and the lists '
      '"triggers", "conditions" and "actions" in current Home Assistant '
      'automation syntax: each trigger has a "trigger" key (state, '
      'numeric_state, time, sun, zone, event, time_pattern), each action an '
      '"action" key ("light.turn_on", "notify.notify", …) with "target" '
      'and "data", or "delay"/"choose"/"if" blocks.',
    )
    ..writeln(
      'Use only these entity ids; if the request needs a device that is '
      'not listed, answer {"error": "<what is missing>"}:',
    );
  for (final d in shown) {
    b.writeln('${d.id}: ${d.name}');
  }
  if (list.length > shown.length) {
    b.writeln('(${list.length - shown.length} more not listed)');
  }
  return b.toString();
}

/// A draft the AI wrote, checked before anything is saved.
@immutable
class AiDraft {
  const AiDraft({
    required this.config,
    this.unknownEntities = const [],
    this.unknownActions = const [],
    this.blocked = const [],
    this.sensitive = const [],
  });

  /// The automation as HA stores it.
  final Map<String, Object?> config;

  /// Entity ids the home does not have (the AI made them up).
  final List<String> unknownEntities;

  /// Actions HA does not offer.
  final List<String> unknownActions;

  /// Actions never saved from a draft ([blockedDomains]).
  final List<String> blocked;

  /// Actions to look at twice ([sensitiveActions]).
  final List<String> sensitive;

  String get alias =>
      config['alias'] is String ? config['alias']! as String : '';
  String get description =>
      config['description'] is String ? config['description']! as String : '';

  bool get canSave =>
      unknownEntities.isEmpty && unknownActions.isEmpty && blocked.isEmpty;
}

/// Why a draft could not even be read.
class AiDraftError implements Exception {
  const AiDraftError(this.message);

  /// The AI's own explanation (`{"error": …}`), or null when the answer
  /// was not an automation at all.
  final String? message;
}

/// The AI's answer (`data` of the AI Task response: text with JSON, maybe
/// in a ```json block, or already an object) as a checked draft.
AiDraft parseAiDraft(
  Object? data, {
  required Set<String> entities,
  required Map<String, Set<String>> services,
}) {
  Object? json = data;
  if (data is String) {
    var text = data.trim();
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
    if (fence != null) text = fence.group(1)!.trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) throw const AiDraftError(null);
    try {
      json = jsonDecode(text.substring(start, end + 1));
    } on FormatException {
      throw const AiDraftError(null);
    }
  }
  if (json is! Map) throw const AiDraftError(null);
  if (json['error'] is String) throw AiDraftError(json['error']! as String);
  List<Object?>? list(String a, String b) =>
      (json as Map)[a] is List ? json[a] as List : json[b] as List?;
  final triggers = list('triggers', 'trigger');
  final actions = list('actions', 'action');
  if (triggers == null ||
      triggers.isEmpty ||
      actions == null ||
      actions.isEmpty) {
    throw const AiDraftError(null);
  }
  final config = <String, Object?>{
    'alias': json['alias'] is String ? json['alias'] : 'Automation',
    'description': json['description'] is String ? json['description'] : '',
    'mode':
        const {'single', 'restart', 'queued', 'parallel'}.contains(json['mode'])
        ? json['mode']
        : 'single',
    'triggers': triggers,
    'conditions': list('conditions', 'condition') ?? const <Object?>[],
    'actions': actions,
  };

  final usedEntities = <String>{};
  final usedActions = <String>{};
  void walk(Object? node) {
    if (node is Map) {
      for (final MapEntry(:key, :value) in node.entries) {
        if (key == 'entity_id') {
          for (final id in value is List ? value : [value]) {
            if (id is String && id != 'all') usedEntities.add(id);
          }
        } else if ((key == 'action' || key == 'service') &&
            value is String &&
            value.contains('.')) {
          usedActions.add(value);
        }
        walk(value);
      }
    } else if (node is List) {
      node.forEach(walk);
    }
  }

  walk(config);
  // `zone.*` and `sun.sun` are entities too, but not devices.
  bool known(String id) =>
      entities.contains(id) || id.startsWith('zone.') || id == 'sun.sun';
  bool offered(String a) {
    final dot = a.indexOf('.');
    return services[a.substring(0, dot)]?.contains(a.substring(dot + 1)) ??
        false;
  }

  return AiDraft(
    config: config,
    unknownEntities: [
      for (final id in usedEntities)
        if (!known(id)) id,
    ]..sort(),
    blocked: [
      for (final a in usedActions)
        if (blockedDomains.contains(a.split('.').first)) a,
    ]..sort(),
    unknownActions: [
      for (final a in usedActions)
        if (!blockedDomains.contains(a.split('.').first) && !offered(a)) a,
    ]..sort(),
    sensitive: [
      for (final a in usedActions)
        if (sensitiveActions.contains(a)) a,
    ]..sort(),
  );
}
