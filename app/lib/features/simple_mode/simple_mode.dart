import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/localization/l10n.dart';
import '../../app/theme/app_theme.dart';
import '../../core/storage/app_preferences.dart';
import '../devices/application/device_providers.dart';
import '../devices/domain/device_command.dart';
import '../devices/domain/device_kind.dart';
import '../devices/domain/smart_home_device.dart';
import '../devices/presentation/device_actions.dart';
import '../devices/presentation/device_presentation.dart';
import '../kiosk/application/kiosk_controller.dart';
import '../kiosk/application/kiosk_now.dart';
import '../kiosk/presentation/pin_dialog.dart';
import '../ha_notify/ha_push.dart';
import '../household/family_messages.dart';
import '../recipes/recipes.dart' show careCheckInEvent, careHelpEvent;

/// "Simple mode" on this device: a few big buttons and nothing else, for
/// someone who wants the lights and the heating, not an app.
@immutable
class SimpleMode {
  const SimpleMode({
    this.enabled = false,
    this.items = const [],
    this.care = false,
    this.name = '',
  });

  factory SimpleMode.fromJson(Map<String, Object?>? json) => SimpleMode(
    enabled: json?['enabled'] == true,
    care: json?['care'] == true,
    name: json?['name'] as String? ?? '',
    items: [
      if (json?['items'] case final List<Object?> list)
        for (final i in list.take(maxItems))
          if (i is String) i,
    ],
  );

  static const maxItems = 8;

  final bool enabled;

  /// Device and scene ids, in order.
  final List<String> items;

  /// "I'm fine" and "Help" on the screen (for someone living alone).
  final bool care;

  /// Who uses it, in the messages ("Grandma").
  final String name;

  SimpleMode copyWith({
    bool? enabled,
    List<String>? items,
    bool? care,
    String? name,
  }) => SimpleMode(
    enabled: enabled ?? this.enabled,
    items: items ?? this.items,
    care: care ?? this.care,
    name: name ?? this.name,
  );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'items': items,
    'care': care,
    'name': name,
  };
}

class SimpleModeController extends Notifier<SimpleMode> {
  static const _key = 'simpleMode';

  @override
  SimpleMode build() =>
      SimpleMode.fromJson(ref.watch(appPreferencesProvider).readJson(_key));

  Future<void> _save(SimpleMode m) async {
    state = m;
    await ref.read(appPreferencesProvider).writeJson(_key, m.toJson());
  }

  Future<void> setEnabled(bool on) => _save(state.copyWith(enabled: on));

  Future<void> setItems(List<String> items) =>
      _save(state.copyWith(items: items.take(SimpleMode.maxItems).toList()));

  Future<void> setCare(bool on, String name) =>
      _save(state.copyWith(care: on, name: name.trim()));
}

final simpleModeProvider = NotifierProvider<SimpleModeController, SimpleMode>(
  SimpleModeController.new,
);

/// Whether the simple screen is in charge (the router keeps it there).
final simpleModeActiveProvider = Provider<bool>(
  (ref) => ref.watch(simpleModeProvider.select((m) => m.enabled)),
);

/// What simple mode can offer: things one tap understands.
bool simpleCandidate(SmartHomeDevice d) =>
    !d.isAuxiliary &&
    (d.kind.isLight ||
        d.kind == DeviceKind.switchDevice ||
        d.kind == DeviceKind.outlet ||
        d.kind == DeviceKind.scene ||
        d.kind == DeviceKind.script ||
        d.kind == DeviceKind.climate ||
        d.kind == DeviceKind.thermostat ||
        d.kind == DeviceKind.blind ||
        d.kind == DeviceKind.curtain ||
        d.kind == DeviceKind.fan ||
        d.kind == DeviceKind.mediaPlayer ||
        d.kind == DeviceKind.speaker ||
        d.kind == DeviceKind.television);

/// Leaving simple mode: the panel's PIN when there is one, else a plain
/// question (so a stray tap does not leave it).
Future<void> leaveSimpleMode(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final controller = ref.read(simpleModeProvider.notifier);
  final bool ok;
  if (ref.read(kioskSettingsProvider).hasPin) {
    ok = await confirmKioskPin(context, ref);
  } else {
    ok =
        await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: Text(l10n.simpleLeaveTitle),
            content: Text(l10n.simpleLeaveBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialog).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                key: const Key('simpleLeaveConfirm'),
                onPressed: () => Navigator.of(dialog).pop(true),
                child: Text(l10n.simpleLeave),
              ),
            ],
          ),
        ) ??
        false;
  }
  if (ok) await controller.setEnabled(false);
}

class SimpleModeScreen extends ConsumerWidget {
  const SimpleModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final items = ref.watch(simpleModeProvider.select((m) => m.items));
    final now = ref.watch(kioskNowProvider);
    final media = MediaQuery.of(context);
    // Large text, at least a quarter larger than the system's.
    final scaler = media.textScaler.clamp(minScaleFactor: 1.25);
    return MediaQuery(
      data: media.copyWith(textScaler: scaler),
      child: Scaffold(
        key: const Key('simpleMode'),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.Hm(l10n.localeName).format(now),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            DateFormat.MMMMEEEEd(l10n.localeName).format(now),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('simpleLeave'),
                      tooltip: l10n.simpleLeave,
                      onPressed: () => leaveSimpleMode(context, ref),
                      icon: const Icon(Icons.lock_outline),
                    ),
                  ],
                ),
                if (ref.watch(simpleModeProvider.select((m) => m.care))) ...[
                  const SizedBox(height: 12),
                  const _CareButtons(),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            l10n.simpleEmpty,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge,
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, c) {
                            final columns = c.maxWidth >= 900
                                ? 4
                                : c.maxWidth >= 600
                                ? 3
                                : 2;
                            return GridView.count(
                              crossAxisCount: columns,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.95,
                              children: [
                                for (final id in items) _SimpleTile(id: id),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "I'm fine" (green) and "Help" (red), big, on top. They fire events
/// the care recipes in Home Assistant wait for, and leave a household
/// message (the app and the wall panel show it).
class _CareButtons extends ConsumerWidget {
  const _CareButtons();

  Future<void> _send(
    BuildContext context,
    WidgetRef ref, {
    required bool help,
  }) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final name = ref.read(simpleModeProvider).name;
    final who = name.isEmpty ? l10n.careSomeone : name;
    if (help) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          icon: const Icon(Icons.sos, size: 48),
          title: Text(l10n.careHelpAsk),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('careHelpConfirm'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text(l10n.careHelpYes),
            ),
          ],
        ),
      );
      if (sure != true) return;
    }
    final sent = await ref.read(haPushProvider.notifier).fireEvent(
      help ? careHelpEvent : careCheckInEvent,
      {'who': who},
    );
    var told = false;
    try {
      await sendFamilyMessage(
        ref,
        l10n,
        personId: null,
        text: help ? l10n.careHelpMessage(who) : l10n.careFineMessage(who),
      );
      told = true;
    } on Object {
      told = false;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          sent || told
              ? (help ? l10n.careHelpSent : l10n.careFineSent)
              : l10n.careNotSent,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    Widget big(Key key, Color color, IconData icon, String label, bool help) =>
        Expanded(
          child: SizedBox(
            height: 72,
            child: FilledButton.icon(
              key: key,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                textStyle: Theme.of(context).textTheme.titleLarge,
              ),
              onPressed: () => _send(context, ref, help: help),
              icon: Icon(icon, size: 30),
              label: Text(label),
            ),
          ),
        );
    return Row(
      children: [
        big(
          const Key('careFine'),
          const Color(0xFF2E7D32),
          Icons.check_circle_outline,
          l10n.careFine,
          false,
        ),
        const SizedBox(width: 12),
        big(
          const Key('careHelp'),
          const Color(0xFFC62828),
          Icons.sos_outlined,
          l10n.careHelp,
          true,
        ),
      ],
    );
  }
}

class _SimpleTile extends ConsumerStatefulWidget {
  const _SimpleTile({required this.id});

  final String id;

  @override
  ConsumerState<_SimpleTile> createState() => _SimpleTileState();
}

class _SimpleTileState extends ConsumerState<_SimpleTile> {
  bool _busy = false;

  Future<void> _run(SmartHomeDevice d, DeviceCommand command) async {
    setState(() => _busy = true);
    await runDeviceCommand(context, ref, d, command);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final d = ref.watch(deviceProvider(widget.id));
    if (d == null) return const SizedBox.shrink();
    final climate =
        d.kind == DeviceKind.climate || d.kind == DeviceKind.thermostat;
    final routine = DevicePresentation.hasQuickActivate(d);
    final on = d.state.isOn == true;
    final accent = context.deviceAccents.of(DevicePresentation.accent(d));
    final bg = on && !climate ? accent.container : scheme.surfaceContainerHigh;
    final fg = on && !climate ? accent.onContainer : scheme.onSurface;
    final target = d.state.targetTemperature;
    final String status = climate
        ? (target == null
              ? DevicePresentation.status(l10n, d)
              : '${target.toStringAsFixed(target % 1 == 0 ? 0 : 1)}°')
        : routine
        ? l10n.simpleStart
        : on
        ? l10n.simpleOn
        : l10n.simpleOff;
    void tap() {
      if (!d.available || _busy) return;
      if (routine) {
        unawaited(_run(d, const Activate()));
      } else if (!climate) {
        unawaited(_run(d, on ? const TurnOff() : const TurnOn()));
      }
    }

    return Semantics(
      button: !climate,
      label: '${d.name}, $status',
      excludeSemantics: !climate,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('simpleTile-${d.id}'),
          onTap: climate ? null : tap,
          child: Opacity(
            opacity: d.available ? 1 : 0.5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // On a narrow phone with large text the words shrink to
                  // fit instead of spilling out; the buttons below never do.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: box.maxWidth,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: box.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    DevicePresentation.icon(d),
                                    size: 48,
                                    color: fg,
                                  ),
                                  const Spacer(),
                                  Text(
                                    d.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: fg,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    status,
                                    style:
                                        (climate
                                                ? theme.textTheme.headlineMedium
                                                : theme.textTheme.headlineSmall)
                                            ?.copyWith(color: fg),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (climate && target != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Big(
                          key: ValueKey('simpleDown-${d.id}'),
                          icon: Icons.remove,
                          label: l10n.simpleCooler,
                          onTap: () =>
                              _run(d, SetTargetTemperature(target - 0.5)),
                        ),
                        _Big(
                          key: ValueKey('simpleUp-${d.id}'),
                          icon: Icons.add,
                          label: l10n.simpleWarmer,
                          onTap: () =>
                              _run(d, SetTargetTemperature(target + 0.5)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;

  /// What TalkBack says ("Warmer").
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: label,
    onPressed: onTap,
    iconSize: 30,
    padding: const EdgeInsets.all(10),
    icon: Icon(icon),
  );
}

/// Settings: turn it on, choose the buttons.
class SimpleModeSettings extends ConsumerWidget {
  const SimpleModeSettings({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final current = ref.read(simpleModeProvider).items;
    final chosen = await showDialog<List<String>>(
      context: context,
      builder: (_) => _SimplePicker(initial: current),
    );
    if (chosen != null) {
      await ref.read(simpleModeProvider.notifier).setItems(chosen);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(simpleModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          key: const Key('simplePick'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.grid_view_rounded),
          title: Text(l10n.simpleTitle),
          subtitle: Text(
            mode.items.isEmpty
                ? l10n.simpleHint
                : l10n.simpleChosen(mode.items.length),
          ),
          trailing: TextButton(
            key: const Key('simpleChoose'),
            onPressed: () => _pick(context, ref),
            child: Text(l10n.simpleChoose),
          ),
        ),
        SwitchListTile(
          key: const Key('simpleCare'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.favorite_border),
          title: Text(l10n.careButtonsSetting),
          subtitle: Text(l10n.careButtonsHint),
          value: mode.care,
          onChanged: (v) =>
              ref.read(simpleModeProvider.notifier).setCare(v, mode.name),
        ),
        if (mode.care)
          TextFormField(
            key: const Key('simpleCareName'),
            initialValue: mode.name,
            decoration: InputDecoration(labelText: l10n.careWho),
            onChanged: (v) =>
                ref.read(simpleModeProvider.notifier).setCare(true, v),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            key: const Key('simpleStart'),
            onPressed: mode.items.isEmpty
                ? null
                : () => ref.read(simpleModeProvider.notifier).setEnabled(true),
            icon: const Icon(Icons.grid_view_rounded),
            label: Text(l10n.simpleStartMode),
          ),
        ),
      ],
    );
  }
}

class _SimplePicker extends ConsumerStatefulWidget {
  const _SimplePicker({required this.initial});

  final List<String> initial;

  @override
  ConsumerState<_SimplePicker> createState() => _SimplePickerState();
}

class _SimplePickerState extends ConsumerState<_SimplePicker> {
  late final List<String> _chosen = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
    final candidates = [
      for (final d in devices.values)
        if (simpleCandidate(d)) d,
    ]..sort((a, b) => a.name.compareTo(b.name));
    return AlertDialog(
      title: Text(l10n.simpleChooseTitle(SimpleMode.maxItems)),
      content: SizedBox(
        width: 420,
        height: 480,
        child: ListView(
          children: [
            for (final d in candidates)
              CheckboxListTile(
                key: ValueKey('simplePick-${d.id}'),
                secondary: Icon(DevicePresentation.icon(d)),
                title: Text(d.name),
                value: _chosen.contains(d.id),
                onChanged:
                    !_chosen.contains(d.id) &&
                        _chosen.length >= SimpleMode.maxItems
                    ? null
                    : (v) => setState(
                        () => v == true
                            ? _chosen.add(d.id)
                            : _chosen.remove(d.id),
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
        FilledButton(
          key: const Key('simplePickSave'),
          onPressed: () => Navigator.of(context).pop(_chosen),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
