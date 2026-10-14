import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../authentication/application/session_controller.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/domain/device_kind.dart';
import '../../devices/domain/smart_home_device.dart';
import '../../devices/presentation/device_history.dart' show historyStateLabel;
import '../../devices/presentation/device_presentation.dart';
import '../domain/simple_automation.dart';

enum _TriggerKind { time, device, sun }

String serviceLabel(AppLocalizations l10n, SmartHomeDevice? d, String svc) =>
    switch (svc) {
      'turn_on' when d?.kind.isRoutine ?? false => l10n.svc_activate,
      'turn_on' => l10n.svc_turn_on,
      'turn_off' => l10n.svc_turn_off,
      'open_cover' => l10n.svc_open_cover,
      'close_cover' => l10n.svc_close_cover,
      'lock' => l10n.svc_lock,
      'start' => l10n.svc_start,
      'return_to_base' => l10n.svc_return_to_base,
      'media_play' => l10n.svc_media_play,
      'media_pause' => l10n.svc_media_pause,
      _ => svc,
    };

/// Builds a simple "when … then …" automation and saves it in HA.
class AutomationEditorScreen extends ConsumerStatefulWidget {
  const AutomationEditorScreen({super.key, this.existingId, this.initial});

  /// Editing: the automation's config id and its parsed content.
  final String? existingId;
  final SimpleAutomation? initial;

  @override
  ConsumerState<AutomationEditorScreen> createState() =>
      _AutomationEditorScreenState();
}

class _AutomationEditorScreenState
    extends ConsumerState<AutomationEditorScreen> {
  final _name = TextEditingController();
  _TriggerKind _kind = _TriggerKind.time;
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);
  final Set<int> _weekdays = {};
  String? _triggerDevice;
  String? _triggerState;
  bool _sunset = true;
  int _offset = 0;
  final List<AutomationAction> _actions = [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    if (a == null) return;
    _name.text = a.alias;
    _actions.addAll(a.actions);
    switch (a.trigger) {
      case TimeTrigger(:final hour, :final minute, :final weekdays):
        _kind = _TriggerKind.time;
        _time = TimeOfDay(hour: hour, minute: minute);
        _weekdays.addAll(weekdays);
      case DeviceTrigger(:final entityId, :final toState):
        _kind = _TriggerKind.device;
        _triggerDevice = entityId;
        _triggerState = toState;
      case SunTrigger(:final sunset, :final offsetMinutes):
        _kind = _TriggerKind.sun;
        _sunset = sunset;
        _offset = offsetMinutes.clamp(-120, 120);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  AutomationTrigger? get _trigger => switch (_kind) {
    _TriggerKind.time => TimeTrigger(
      _time.hour,
      _time.minute,
      weekdays: {..._weekdays},
    ),
    _TriggerKind.device when _triggerDevice != null && _triggerState != null =>
      DeviceTrigger(_triggerDevice!, _triggerState!),
    _TriggerKind.sun => SunTrigger(sunset: _sunset, offsetMinutes: _offset),
    _ => null,
  };

  Future<String?> _pickDevice(bool Function(SmartHomeDevice) filter) =>
      showDialog<String>(
        context: context,
        builder: (_) => _DevicePicker(filter: filter),
      );

  Future<void> _addAction() async {
    final l10n = context.l10n;
    final id = await _pickDevice((d) => actionServicesFor(d).isNotEmpty);
    if (id == null || !mounted) return;
    final d = ref.read(deviceProvider(id));
    if (d == null) return;
    final services = actionServicesFor(d);
    final svc = services.length == 1
        ? services.first
        : await showDialog<String>(
            context: context,
            builder: (context) => SimpleDialog(
              title: Text(d.name),
              children: [
                for (final s in services)
                  SimpleDialogOption(
                    key: ValueKey('svc-$s'),
                    onPressed: () => Navigator.of(context).pop(s),
                    child: Text(serviceLabel(l10n, d, s)),
                  ),
              ],
            ),
          );
    if (svc != null) setState(() => _actions.add(AutomationAction(id, svc)));
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final trigger = _trigger;
    if (trigger == null || _actions.isEmpty) {
      setState(() => _error = l10n.autoIncomplete);
      return;
    }
    final api = ref.read(homeAssistantApiProvider);
    if (api == null) return;
    final name = _name.text.trim().isEmpty ? _summary() : _name.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final id =
          widget.existingId ?? DateTime.now().millisecondsSinceEpoch.toString();
      await api.saveAutomation(
        id,
        SimpleAutomation(
          alias: name,
          trigger: trigger,
          actions: _actions,
        ).toConfig(id),
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.autoSaved)));
      navigator.pop();
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l10n.autoSaveFailed;
        });
      }
    }
  }

  /// A readable default name, e.g. "07:00 → Hallway light".
  String _summary() {
    final l10n = context.l10n;
    final when = switch (_kind) {
      _TriggerKind.time => _time.format(context),
      _TriggerKind.device =>
        ref.read(deviceProvider(_triggerDevice ?? ''))?.name ?? '',
      _TriggerKind.sun => _sunset ? l10n.autoSunset : l10n.autoSunrise,
    };
    final what = _actions
        .map((a) => ref.read(deviceProvider(a.entityId))?.name ?? a.entityId)
        .join(', ');
    return '$when → $what';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    final trigDevice = _triggerDevice == null
        ? null
        : ref.watch(deviceProvider(_triggerDevice!));

    Widget header(String text) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(text, style: theme.textTheme.titleMedium),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingId == null ? l10n.autoNew : l10n.autoEdit),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(l10n.autoHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            key: const Key('autoName'),
            controller: _name,
            decoration: InputDecoration(
              labelText: l10n.autoName,
              hintText: l10n.autoNameHint,
            ),
          ),
          header(l10n.autoWhen),
          SegmentedButton<_TriggerKind>(
            key: const Key('autoTriggerKind'),
            segments: [
              ButtonSegment(
                value: _TriggerKind.time,
                icon: const Icon(Icons.schedule),
                label: Text(l10n.autoTriggerTime),
              ),
              ButtonSegment(
                value: _TriggerKind.device,
                icon: const Icon(Icons.sensors),
                label: Text(l10n.autoTriggerDevice),
              ),
              ButtonSegment(
                value: _TriggerKind.sun,
                icon: const Icon(Icons.wb_twilight),
                label: Text(l10n.autoTriggerSun),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 12),
          ...switch (_kind) {
            _TriggerKind.time => [
              OutlinedButton.icon(
                key: const Key('autoTime'),
                onPressed: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _time,
                  );
                  if (t != null) setState(() => _time = t);
                },
                icon: const Icon(Icons.schedule),
                label: Text(_time.format(context)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      key: ValueKey('autoDay-$d'),
                      label: Text(
                        DateFormat.E(locale).format(DateTime(2024, 1, d)),
                      ),
                      selected: _weekdays.contains(d),
                      onSelected: (v) => setState(
                        () => v ? _weekdays.add(d) : _weekdays.remove(d),
                      ),
                    ),
                ],
              ),
              if (_weekdays.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.autoEveryDay,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
            _TriggerKind.device => [
              OutlinedButton.icon(
                key: const Key('autoTriggerDevice'),
                onPressed: () async {
                  final id = await _pickDevice(
                    (d) => triggerStatesFor(d).isNotEmpty,
                  );
                  if (id == null) return;
                  final d = ref.read(deviceProvider(id));
                  setState(() {
                    _triggerDevice = id;
                    _triggerState = d == null
                        ? null
                        : triggerStatesFor(d).first;
                  });
                },
                icon: Icon(
                  trigDevice == null
                      ? Icons.add
                      : DevicePresentation.icon(trigDevice),
                ),
                label: Text(trigDevice?.name ?? l10n.autoPickDevice),
              ),
              if (trigDevice != null) ...[
                const SizedBox(height: 8),
                Text(l10n.autoChangesTo, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final st in triggerStatesFor(trigDevice))
                      ChoiceChip(
                        key: ValueKey('autoState-$st'),
                        label: Text(historyStateLabel(l10n, st)),
                        selected: _triggerState == st,
                        onSelected: (_) => setState(() => _triggerState = st),
                      ),
                  ],
                ),
              ],
            ],
            _TriggerKind.sun => [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.wb_sunny_outlined),
                    label: Text(l10n.autoSunrise),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.nights_stay_outlined),
                    label: Text(l10n.autoSunset),
                  ),
                ],
                selected: {_sunset},
                onSelectionChanged: (s) => setState(() => _sunset = s.first),
              ),
              Slider(
                value: _offset.toDouble(),
                min: -120,
                max: 120,
                divisions: 16,
                label: l10n.autoOffset(_offset),
                onChanged: (v) => setState(() => _offset = v.round()),
              ),
              Text(
                l10n.autoOffset(_offset),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          },
          header(l10n.autoThen),
          for (final (i, a) in _actions.indexed)
            Card(
              child: Consumer(
                builder: (context, ref, _) {
                  final d = ref.watch(deviceProvider(a.entityId));
                  return ListTile(
                    leading: Icon(
                      d == null ? Icons.bolt : DevicePresentation.icon(d),
                    ),
                    title: Text(d?.name ?? a.entityId),
                    subtitle: Text(serviceLabel(l10n, d, a.service)),
                    trailing: IconButton(
                      tooltip: l10n.cancel,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _actions.removeAt(i)),
                    ),
                  );
                },
              ),
            ),
          OutlinedButton.icon(
            key: const Key('autoAddAction'),
            onPressed: _addAction,
            icon: const Icon(Icons.add),
            label: Text(l10n.autoAddAction),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            InlineNotice.error(_error!),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('autoSave'),
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(l10n.autoSave),
          ),
        ],
      ),
    );
  }
}

/// Searchable list of devices accepted by [filter].
class _DevicePicker extends ConsumerStatefulWidget {
  const _DevicePicker({required this.filter});

  final bool Function(SmartHomeDevice) filter;

  @override
  ConsumerState<_DevicePicker> createState() => _DevicePickerState();
}

class _DevicePickerState extends ConsumerState<_DevicePicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
    final list =
        devices.values
            .where(
              (d) =>
                  !d.isAuxiliary &&
                  d.kind != DeviceKind.unknown &&
                  widget.filter(d) &&
                  d.name.toLowerCase().contains(_q.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return AlertDialog(
      title: Text(l10n.autoPickDevice),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 440,
        height: 460,
        child: Column(
          children: [
            TextField(
              key: const Key('pickSearch'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchHint,
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final d in list)
                    ListTile(
                      key: ValueKey('pick-${d.id}'),
                      leading: Icon(DevicePresentation.icon(d)),
                      title: Text(d.name),
                      onTap: () => Navigator.of(context).pop(d.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
