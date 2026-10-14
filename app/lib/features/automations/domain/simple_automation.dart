import 'package:flutter/foundation.dart';

import '../../devices/domain/device_kind.dart';
import '../../devices/domain/smart_home_device.dart';

/// When an automation runs.
sealed class AutomationTrigger {
  const AutomationTrigger();
}

/// At a time of day, optionally only on some weekdays (1 = Monday).
class TimeTrigger extends AutomationTrigger {
  const TimeTrigger(this.hour, this.minute, {this.weekdays = const {}});

  final int hour;
  final int minute;

  /// Empty = every day.
  final Set<int> weekdays;
}

/// When a device changes to [toState] (HA state, e.g. `on`, `home`).
class DeviceTrigger extends AutomationTrigger {
  const DeviceTrigger(this.entityId, this.toState);

  final String entityId;
  final String toState;
}

/// At sunrise or sunset, shifted by [offsetMinutes].
class SunTrigger extends AutomationTrigger {
  const SunTrigger({required this.sunset, this.offsetMinutes = 0});

  final bool sunset;
  final int offsetMinutes;
}

/// What an automation does: call [service] on [entityId].
@immutable
class AutomationAction {
  const AutomationAction(this.entityId, this.service);

  final String entityId;

  /// Service name in the entity's domain, e.g. `turn_on`, `close_cover`.
  final String service;

  String get domain => entityId.split('.').first;
}

/// A small automation the app can create; saved as a normal Home
/// Assistant automation (visible and editable in HA afterwards).
@immutable
class SimpleAutomation {
  const SimpleAutomation({
    required this.alias,
    required this.trigger,
    required this.actions,
  });

  final String alias;
  final AutomationTrigger trigger;
  final List<AutomationAction> actions;

  static const _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// HA automation config (2024.10+ format: `triggers` / `actions`).
  Map<String, Object?> toConfig(String id) {
    final t = trigger;
    return {
      'id': id,
      'alias': alias,
      'description': 'Open Smart Home',
      'mode': 'single',
      'triggers': [
        switch (t) {
          TimeTrigger() => {
            'trigger': 'time',
            'at': '${_two(t.hour)}:${_two(t.minute)}:00',
          },
          DeviceTrigger() => {
            'trigger': 'state',
            'entity_id': t.entityId,
            'to': t.toState,
          },
          SunTrigger() => {
            'trigger': 'sun',
            'event': t.sunset ? 'sunset' : 'sunrise',
            'offset': _offset(t.offsetMinutes),
          },
        },
      ],
      'conditions': [
        if (t is TimeTrigger && t.weekdays.isNotEmpty && t.weekdays.length < 7)
          {
            'condition': 'time',
            'weekday': [
              for (final d in (t.weekdays.toList()..sort())) _days[d - 1],
            ],
          },
      ],
      'actions': [
        for (final a in actions)
          {
            'action': '${a.domain}.${a.service}',
            'target': {'entity_id': a.entityId},
          },
      ],
    };
  }

  /// Reads a config back if it has the simple shape this editor makes:
  /// one time/state/sun trigger, optional weekday condition, and actions
  /// that call a service on entity targets. `null` = edit in HA instead.
  static SimpleAutomation? tryParse(Map<String, Object?> config) {
    List<Object?> list(String plural, String singular) =>
        switch (config[plural] ?? config[singular]) {
          final List<Object?> l => l,
          final Map<Object?, Object?> m => [m],
          _ => const [],
        };
    final triggers = list('triggers', 'trigger');
    final conditions = list('conditions', 'condition');
    final actions = list('actions', 'action');
    if (triggers.length != 1 || triggers.first is! Map) return null;
    final t = triggers.first! as Map;
    final kind = t['trigger'] ?? t['platform'];

    var weekdays = <int>{};
    for (final c in conditions) {
      if (c is Map && c['condition'] == 'time' && c['weekday'] is List) {
        weekdays = {
          for (final d in c['weekday'] as List)
            if (_days.indexOf('$d') case final i when i >= 0) i + 1,
        };
      } else {
        return null;
      }
    }

    final AutomationTrigger trigger;
    switch (kind) {
      case 'time':
        final at = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch('${t['at']}');
        if (at == null) return null;
        trigger = TimeTrigger(
          int.parse(at[1]!),
          int.parse(at[2]!),
          weekdays: weekdays,
        );
      case 'state':
        final id = t['entity_id'];
        final to = t['to'];
        final entity = id is List && id.length == 1 ? id.first : id;
        if (entity is! String || to is! String) return null;
        trigger = DeviceTrigger(entity, to);
      case 'sun':
        final m = RegExp(r'^(-?)(\d{1,2}):(\d{2})')
            .firstMatch('${t['offset'] ?? '00:00:00'}');
        final minutes = m == null
            ? 0
            : (int.parse(m[2]!) * 60 + int.parse(m[3]!)) *
                  (m[1] == '-' ? -1 : 1);
        trigger = SunTrigger(
          sunset: t['event'] == 'sunset',
          offsetMinutes: minutes,
        );
      default:
        return null;
    }
    if (kind != 'time' && weekdays.isNotEmpty) return null;

    final parsed = <AutomationAction>[];
    for (final a in actions) {
      if (a is! Map) return null;
      final service = (a['action'] ?? a['service']);
      final target = a['target'];
      final id = target is Map ? target['entity_id'] : a['entity_id'];
      final ids = id is List ? id : [id];
      if (service is! String || !service.contains('.')) return null;
      for (final e in ids) {
        if (e is! String) return null;
        parsed.add(AutomationAction(e, service.split('.').last));
      }
    }
    if (parsed.isEmpty) return null;
    return SimpleAutomation(
      alias: config['alias'] is String ? config['alias']! as String : '',
      trigger: trigger,
      actions: parsed,
    );
  }

  static String _offset(int minutes) {
    final sign = minutes < 0 ? '-' : '';
    final m = minutes.abs();
    return '$sign${_two(m ~/ 60)}:${_two(m % 60)}:00';
  }
}

/// States a device can be watched for (`to:`), as (HA state, kind of label).
List<String> triggerStatesFor(SmartHomeDevice d) => switch (d.kind) {
  DeviceKind.person => const ['home', 'not_home'],
  DeviceKind.lock => const ['unlocked', 'locked'],
  DeviceKind.blind ||
  DeviceKind.curtain ||
  DeviceKind.garageDoor => const ['open', 'closed'],
  _ when d.kind.isSensor && d.state.numericValue != null => const [],
  DeviceKind.camera ||
  DeviceKind.weather ||
  DeviceKind.select ||
  DeviceKind.number ||
  DeviceKind.unknown => const [],
  _ when d.kind.isRoutine => const [],
  _ => const ['on', 'off'],
};

/// Services an automation may call on a device. Unlocking and disarming
/// are left out on purpose: they belong in Home Assistant's own editor.
List<String> actionServicesFor(SmartHomeDevice d) => switch (d.kind) {
  DeviceKind.scene || DeviceKind.script => const ['turn_on'],
  DeviceKind.blind || DeviceKind.curtain => const ['open_cover', 'close_cover'],
  DeviceKind.lock => const ['lock'],
  DeviceKind.vacuum => const ['start', 'return_to_base'],
  DeviceKind.mediaPlayer ||
  DeviceKind.speaker ||
  DeviceKind.television => const ['media_play', 'media_pause', 'turn_off'],
  _ when d.kind.isLight => const ['turn_on', 'turn_off'],
  DeviceKind.switchDevice ||
  DeviceKind.outlet ||
  DeviceKind.fan ||
  DeviceKind.climate ||
  DeviceKind.thermostat ||
  DeviceKind.humidifier ||
  DeviceKind.dehumidifier ||
  DeviceKind.siren => const ['turn_on', 'turn_off'],
  _ => const [],
};
