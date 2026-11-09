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
  RecipeKind.inactivity => Icons.accessibility_new,
  RecipeKind.checkIn => Icons.waving_hand_outlined,
  RecipeKind.help => Icons.sos_outlined,
  RecipeKind.irrigation => Icons.grass,
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
  RecipeKind.inactivity =>
    d.kind == DeviceKind.motionSensor ||
        d.kind == DeviceKind.occupancySensor ||
        d.kind == DeviceKind.contactSensor,
  RecipeKind.checkIn || RecipeKind.help => false,
  // Soil moisture sensors (numeric, %).
  RecipeKind.irrigation =>
    d.id.startsWith('sensor.') && d.metadata.haDeviceClass == 'moisture',
};

bool _targetFor(RecipeKind k, SmartHomeDevice d) => switch (k) {
  // A water valve, or a switch that drives one.
  RecipeKind.leak =>
    d.id.startsWith('valve.') || d.kind == DeviceKind.switchDevice,
  RecipeKind.followPresence || RecipeKind.nightLight => d.kind.isLight,
  RecipeKind.irrigation =>
    d.id.startsWith('valve.') || d.kind == DeviceKind.switchDevice,
  _ => false,
};

bool _hasTargets(RecipeKind k) =>
    k == RecipeKind.leak ||
    k == RecipeKind.irrigation ||
    k == RecipeKind.followPresence ||
    k == RecipeKind.nightLight;

/// Ends with the "Got it" escalation (phones, waiting).
bool _escalates(RecipeKind k) =>
    k == RecipeKind.escalation ||
    k == RecipeKind.inactivity ||
    k == RecipeKind.checkIn ||
    k == RecipeKind.help;

bool _care(RecipeKind k) =>
    k == RecipeKind.inactivity ||
    k == RecipeKind.checkIn ||
    k == RecipeKind.help;

bool _hasMinutes(RecipeKind k) =>
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
                              : k == RecipeKind.irrigation
                              ? 10
                              : k == RecipeKind.nightLight
                              ? 2
                              : k == RecipeKind.inactivity
                              ? 240
                              : 5,
                          targets: _escalates(k) ? [?phone] : const [],
                          onlyAtNight: k == RecipeKind.followPresence,
                          at: k == RecipeKind.irrigation ? '06:00' : '10:00',
                          weather: k == RecipeKind.irrigation
                              ? devices.values
                                    .where((d) => d.id.startsWith('weather.'))
                                    .firstOrNull
                                    ?.id
                              : null,
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
    final weatherId = devices.values
        .where((d) => d.id.startsWith('weather.'))
        .firstOrNull
        ?.id;
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
          if (_care(k)) ...[
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('recipeWho'),
              initialValue: _r.who,
              decoration: InputDecoration(labelText: l10n.careWho),
              onChanged: (v) => setState(() => _r = _r.copyWith(who: v)),
            ),
          ],
          if (k == RecipeKind.checkIn || k == RecipeKind.irrigation)
            ListTile(
              key: const Key('recipeAt'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(
                k == RecipeKind.irrigation ? l10n.irrigationAt : l10n.careBy,
              ),
              trailing: Text(_r.at, style: theme.textTheme.titleLarge),
              onTap: () async {
                final p = _r.at.split(':');
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: int.tryParse(p.first) ?? 10,
                    minute: int.tryParse(p.last) ?? 0,
                  ),
                );
                if (t == null) return;
                String two(int v) => v.toString().padLeft(2, '0');
                setState(
                  () => _r = _r.copyWith(at: '${two(t.hour)}:${two(t.minute)}'),
                );
              },
            ),
          if (k == RecipeKind.inactivity) ...[
            const SizedBox(height: 12),
            Text(l10n.careStillFor((_r.minutes / 60).round())),
            Slider(
              value: (_r.minutes / 60).clamp(1, 8).toDouble(),
              min: 1,
              max: 8,
              divisions: 7,
              label: '${(_r.minutes / 60).round()} h',
              onChanged: (v) =>
                  setState(() => _r = _r.copyWith(minutes: v.round() * 60)),
            ),
          ],
          if (k != RecipeKind.lastOut &&
              !(k == RecipeKind.checkIn || k == RecipeKind.help))
            _pick(
              k == RecipeKind.irrigation
                  ? l10n.irrigationSoil
                  : l10n.recipeWatch,
              sorted((d) => _sensorFor(k, d)),
              _r.sensors,
              (v) => setState(() => _r = _r.copyWith(sensors: v)),
              empty: l10n.recipeNoSensors,
            ),
          if (_hasTargets(k))
            _pick(
              k == RecipeKind.leak
                  ? l10n.recipeValves
                  : k == RecipeKind.irrigation
                  ? l10n.irrigationZones
                  : l10n.recipeLights,
              sorted((d) => _targetFor(k, d)),
              _r.targets,
              (v) => setState(() => _r = _r.copyWith(targets: v)),
              empty: l10n.recipeNoTargets,
            ),
          if (_escalates(k)) ...[
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
            const SizedBox(height: 12),
            Text(l10n.escalationWait(_r.waitMinutes)),
            Slider(
              value: _r.waitMinutes.clamp(1, 15).toDouble(),
              min: 1,
              max: 15,
              divisions: 14,
              label: '${_r.waitMinutes}',
              onChanged: (v) =>
                  setState(() => _r = _r.copyWith(waitMinutes: v.round())),
            ),
          ],
          if (_hasMinutes(k)) ...[
            const SizedBox(height: 12),
            Text(
              k == RecipeKind.leftOpen
                  ? l10n.recipeLeftOpenAfter(_r.minutes)
                  : k == RecipeKind.nightLight
                  ? l10n.recipeNightFor(_r.minutes)
                  : l10n.recipeOffAfter(_r.minutes),
            ),
            Slider(
              value: _r.minutes.toDouble(),
              min: 1,
              max: k == RecipeKind.leftOpen ? 60 : 30,
              divisions: k == RecipeKind.leftOpen ? 59 : 29,
              label: '${_r.minutes}',
              onChanged: (v) =>
                  setState(() => _r = _r.copyWith(minutes: v.round())),
            ),
          ],
          if (k == RecipeKind.irrigation) ...[
            const SizedBox(height: 12),
            Text(l10n.irrigationMinutes(_r.minutes)),
            Slider(
              key: const Key('irrigationMinutes'),
              value: _r.minutes.clamp(1, 60).toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              label: '${_r.minutes}',
              onChanged: (v) =>
                  setState(() => _r = _r.copyWith(minutes: v.round())),
            ),
            if (_r.sensors.isNotEmpty) ...[
              Text(l10n.irrigationThreshold(_r.threshold)),
              Slider(
                value: _r.threshold.clamp(10, 80).toDouble(),
                min: 10,
                max: 80,
                divisions: 14,
                label: '${_r.threshold} %',
                onChanged: (v) =>
                    setState(() => _r = _r.copyWith(threshold: v.round())),
              ),
            ],
            SwitchListTile(
              key: const Key('irrigationRain'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.irrigationSkipRain),
              subtitle: Text(
                weatherId == null
                    ? l10n.irrigationNoWeather
                    : l10n.irrigationSkipRainHint(rainSkipMm),
              ),
              value: _r.weather != null,
              onChanged: weatherId == null
                  ? null
                  : (v) => setState(
                      () => _r = v
                          ? _r.copyWith(weather: weatherId)
                          : _r.copyWith(clearWeather: true),
                    ),
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
