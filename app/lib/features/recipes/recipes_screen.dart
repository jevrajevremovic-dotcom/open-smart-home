import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/l10n.dart';
import '../../core/errors/app_failure.dart';
import '../../core/errors/failure_messages.dart';
import '../authentication/application/session_controller.dart';
import '../devices/application/device_providers.dart';
import '../devices/domain/device_kind.dart';
import '../devices/domain/smart_home_device.dart';
import '../devices/presentation/device_presentation.dart';
import '../ha_notify/ha_push.dart';
import '../add_device/application/add_device_providers.dart';
import 'recipes.dart';

IconData _icon(RecipeKind k) => switch (k) {
  RecipeKind.leak => Icons.water_damage_outlined,
  RecipeKind.smoke => Icons.local_fire_department_outlined,
  RecipeKind.followPresence => Icons.directions_walk,
  RecipeKind.nightLight => Icons.nightlight_outlined,
  RecipeKind.leftOpen => Icons.door_front_door_outlined,
  RecipeKind.lastOut => Icons.logout,
  RecipeKind.escalation => Icons.notification_important_outlined,
};

/// What each recipe watches and acts on.
bool _sensorFor(RecipeKind k, SmartHomeDevice d) => switch (k) {
  RecipeKind.leak => d.kind == DeviceKind.waterLeakSensor,
  RecipeKind.smoke =>
    d.kind == DeviceKind.smokeSensor || d.kind == DeviceKind.coSensor,
  RecipeKind.followPresence || RecipeKind.nightLight =>
    d.kind == DeviceKind.motionSensor || d.kind == DeviceKind.occupancySensor,
  RecipeKind.leftOpen => d.kind == DeviceKind.contactSensor,
  RecipeKind.lastOut => false,
  RecipeKind.escalation =>
    d.kind == DeviceKind.waterLeakSensor ||
        d.kind == DeviceKind.smokeSensor ||
        d.kind == DeviceKind.coSensor ||
        d.kind == DeviceKind.alarm,
};

bool _targetFor(RecipeKind k, SmartHomeDevice d) => switch (k) {
  // A water valve, or a switch that drives one.
  RecipeKind.leak =>
    d.id.startsWith('valve.') || d.kind == DeviceKind.switchDevice,
  RecipeKind.followPresence || RecipeKind.nightLight => d.kind.isLight,
  _ => false,
};

bool _hasTargets(RecipeKind k) =>
    k == RecipeKind.leak ||
    k == RecipeKind.followPresence ||
    k == RecipeKind.nightLight;

bool _hasMinutes(RecipeKind k) =>
    k == RecipeKind.escalation ||
    k == RecipeKind.followPresence ||
    k == RecipeKind.nightLight ||
    k == RecipeKind.leftOpen;

/// Ready-made automations: what is on, and what can be added.
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  bool _busy = false;

  void _say(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _open(Recipe start) async {
    final l10n = context.l10n;
    final result = await showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _RecipeSheet(initial: start),
    );
    final api = ref.read(homeAssistantApiProvider);
    if (result == null || api == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await api.saveAutomation(result.id, result.automation(l10n));
      _say(l10n.recipeSaved(recipeTitle(l10n, result.kind)));
    } on AppFailure catch (e) {
      _say(failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(String id) async {
    final api = ref.read(homeAssistantApiProvider);
    if (api == null) return;
    try {
      final r = Recipe.fromAutomation(await api.fetchAutomation(id));
      if (r != null && mounted) await _open(r);
    } on AppFailure catch (e) {
      if (mounted) _say(failureMessage(context.l10n, e));
    }
  }

  Future<void> _remove(String id) async {
    final api = ref.read(homeAssistantApiProvider);
    if (api == null) return;
    setState(() => _busy = true);
    try {
      await api.deleteAutomation(id);
    } on AppFailure catch (e) {
      if (mounted) _say(failureMessage(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final saved = ref.watch(savedRecipeIdsProvider);
    final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
    String nameOf(String id) =>
        devices.values
            .where((d) => d.metadata.configId == id)
            .firstOrNull
            ?.name ??
        id;
    final phone = ref.watch(haPushProvider).value?.notifyService;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recipesTitle)),
      body: ListView(
        key: const Key('recipesList'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(l10n.recipesHint, style: theme.textTheme.bodyMedium),
          if (_busy) const LinearProgressIndicator(),
          if (saved.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.recipesOn, style: theme.textTheme.titleSmall),
            for (final id in saved)
              ListTile(
                key: ValueKey('recipeSaved-$id'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(nameOf(id)),
                onTap: _busy ? null : () => _edit(id),
                trailing: IconButton(
                  key: ValueKey('recipeRemove-$id'),
                  tooltip: l10n.recipeRemove,
                  onPressed: _busy ? null : () => _remove(id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(l10n.recipesAdd, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final k in RecipeKind.values)
            Card(
              child: ListTile(
                key: ValueKey('recipe-${k.name}'),
                leading: Icon(_icon(k), color: theme.colorScheme.primary),
                title: Text(recipeTitle(l10n, k)),
                subtitle: Text(recipeHint(l10n, k)),
                isThreeLine: true,
                onTap: _busy
                    ? null
                    : () => _open(
                        Recipe(
                          kind: k,
                          phone: phone,
                          minutes: k == RecipeKind.leftOpen
                              ? 15
                              : k == RecipeKind.nightLight ||
                                    k == RecipeKind.escalation
                              ? 2
                              : 5,
                          targets: k == RecipeKind.escalation
                              ? [?phone]
                              : const [],
                          onlyAtNight: k == RecipeKind.followPresence,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The choices of one recipe.
class _RecipeSheet extends ConsumerStatefulWidget {
  const _RecipeSheet({required this.initial});

  final Recipe initial;

  @override
  ConsumerState<_RecipeSheet> createState() => _RecipeSheetState();
}

class _RecipeSheetState extends ConsumerState<_RecipeSheet> {
  late Recipe _r = widget.initial;

  Widget _pick(
    String title,
    List<SmartHomeDevice> options,
    List<String> chosen,
    void Function(List<String>) onChanged, {
    required String empty,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(title, style: theme.textTheme.titleSmall),
        if (options.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              empty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final d in options)
          CheckboxListTile(
            key: ValueKey('recipePick-${d.id}'),
            contentPadding: EdgeInsets.zero,
            secondary: Icon(DevicePresentation.icon(d)),
            title: Text(d.name),
            value: chosen.contains(d.id),
            onChanged: (v) => onChanged(
              v == true
                  ? [...chosen, d.id]
                  : [...chosen.where((x) => x != d.id)],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final k = _r.kind;
    final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
    List<SmartHomeDevice> sorted(bool Function(SmartHomeDevice) test) =>
        devices.values.where((d) => !d.isAuxiliary && test(d)).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final phone = ref.watch(haPushProvider).value?.notifyService;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        key: const Key('recipeSheet'),
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(recipeTitle(l10n, k), style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(recipeHint(l10n, k)),
          if (k != RecipeKind.lastOut)
            _pick(
              l10n.recipeWatch,
              sorted((d) => _sensorFor(k, d)),
              _r.sensors,
              (v) => setState(() => _r = _r.copyWith(sensors: v)),
              empty: l10n.recipeNoSensors,
            ),
          if (_hasTargets(k))
            _pick(
              k == RecipeKind.leak ? l10n.recipeValves : l10n.recipeLights,
              sorted((d) => _targetFor(k, d)),
              _r.targets,
              (v) => setState(() => _r = _r.copyWith(targets: v)),
              empty: l10n.recipeNoTargets,
            ),
          if (k == RecipeKind.escalation) ...[
            _phones(
              l10n.escalationFirstPhones,
              _r.targets,
              (v) => setState(() => _r = _r.copyWith(targets: v)),
            ),
            _phones(
              l10n.escalationOtherPhones,
              _r.others,
              (v) => setState(() => _r = _r.copyWith(others: v)),
            ),
          ],
          if (_hasMinutes(k)) ...[
            const SizedBox(height: 12),
            Text(
              k == RecipeKind.escalation
                  ? l10n.escalationWait(_r.minutes)
                  : k == RecipeKind.leftOpen
                  ? l10n.recipeLeftOpenAfter(_r.minutes)
                  : k == RecipeKind.nightLight
                  ? l10n.recipeNightFor(_r.minutes)
                  : l10n.recipeOffAfter(_r.minutes),
            ),
            Slider(
              value: _r.minutes.toDouble(),
              min: 1,
              max: k == RecipeKind.leftOpen
                  ? 60
                  : k == RecipeKind.escalation
                  ? 15
                  : 30,
              divisions: k == RecipeKind.leftOpen
                  ? 59
                  : k == RecipeKind.escalation
                  ? 14
                  : 29,
              label: '${_r.minutes}',
              onChanged: (v) =>
                  setState(() => _r = _r.copyWith(minutes: v.round())),
            ),
          ],
          if (k == RecipeKind.followPresence)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.recipeOnlyDark),
              value: _r.onlyAtNight,
              onChanged: (v) =>
                  setState(() => _r = _r.copyWith(onlyAtNight: v)),
            ),
          if (_tells(k))
            SwitchListTile(
              key: const Key('recipePhone'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.recipeTellPhone),
              subtitle: Text(
                phone == null ? l10n.recipePhoneMissing : l10n.recipeTellAll,
              ),
              value: _r.phone != null,
              onChanged: phone == null
                  ? null
                  : (v) => setState(
                      () => _r = v
                          ? _r.copyWith(phone: phone)
                          : _r.copyWith(clearPhone: true),
                    ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('recipeSave'),
            onPressed: _r.complete ? () => Navigator.of(context).pop(_r) : null,
            icon: const Icon(Icons.check),
            label: Text(l10n.recipeSave),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.recipeRunsInHa,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Phones registered in Home Assistant (`notify.mobile_app_…`).
  Widget _phones(
    String title,
    List<String> chosen,
    void Function(List<String>) onChanged,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final services = ref.watch(haServicesProvider).value?['notify'] ?? {};
    final phones = [
      for (final s in services)
        if (s.startsWith('mobile_app_')) 'notify.$s',
    ]..sort();
    String label(String id) =>
        id.substring('notify.mobile_app_'.length).replaceAll('_', ' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(title, style: theme.textTheme.titleSmall),
        if (phones.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.escalationNoPhones,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final p in phones)
          CheckboxListTile(
            key: ValueKey('recipePhone-$title-$p'),
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.smartphone),
            title: Text(label(p)),
            value: chosen.contains(p),
            onChanged: (v) => onChanged(
              v == true ? [...chosen, p] : [...chosen.where((x) => x != p)],
            ),
          ),
      ],
    );
  }

  static bool _tells(RecipeKind k) =>
      k == RecipeKind.leak ||
      k == RecipeKind.smoke ||
      k == RecipeKind.leftOpen ||
      k == RecipeKind.lastOut;
}
