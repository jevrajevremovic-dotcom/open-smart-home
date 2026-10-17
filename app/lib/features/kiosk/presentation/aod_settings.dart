import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../../devices/application/device_providers.dart';
import '../application/kiosk_controller.dart';
import '../data/kiosk_layout.dart';
import '../data/kiosk_settings.dart';
import '../../../core/widgets/time_picker.dart';
import 'kiosk_layout_view.dart' show pickKioskPanelDevice;

/// Kiosk settings: the always-on screen and the morning screen.
class AodSettings extends ConsumerWidget {
  const AodSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final s = ref.watch(kioskSettingsProvider);
    final controller = ref.read(kioskSettingsProvider.notifier);
    String time(int minutes) =>
        TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);

    Future<int?> pick(int current, String help) async {
      final t = await showAppTimePicker(
        context: context,
        helpText: help,
        initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      );
      return t == null ? null : t.hour * 60 + t.minute;
    }

    String focusLabel(AodFocus f) => switch (f) {
      AodFocus.none => l10n.aodFocusNone,
      AodFocus.nextEvent => l10n.aodFocusNextEvent,
      AodFocus.list => l10n.aodFocusList,
      AodFocus.device => l10n.aodFocusDevice,
      AodFocus.energy => l10n.aodFocusEnergy,
      AodFocus.media => l10n.aodFocusMedia,
      AodFocus.home => l10n.aodFocusHome,
    };
    final needsEntity =
        s.aodFocus == AodFocus.list || s.aodFocus == AodFocus.device;
    final entity = s.aodEntityId == null
        ? null
        : ref.watch(deviceProvider(s.aodEntityId!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(l10n.aodTitle, style: theme.textTheme.labelLarge),
        ),
        Text(l10n.aodHint, style: theme.textTheme.bodySmall),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.aodFocus),
          trailing: DropdownButton<AodFocus>(
            key: const Key('aodFocus'),
            value: s.aodFocus,
            items: [
              for (final f in AodFocus.values)
                DropdownMenuItem(value: f, child: Text(focusLabel(f))),
            ],
            onChanged: (v) => v == null
                ? null
                : controller.update(
                    (k) => k.copyWith(aodFocus: v, clearAodEntity: true),
                  ),
          ),
        ),
        if (needsEntity)
          ListTile(
            key: const Key('aodEntity'),
            contentPadding: const EdgeInsets.only(left: 16),
            title: Text(entity?.name ?? l10n.aodChoose),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final id = await pickKioskPanelDevice(
                context,
                s.aodFocus == AodFocus.list
                    ? KioskPanelType.lists
                    : KioskPanelType.device,
              );
              if (id != null) {
                await controller.update((k) => k.copyWith(aodEntityId: id));
              }
            },
          ),
        SwitchListTile(
          key: const Key('morningScreen'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.morningScreen),
          subtitle: Text(
            s.morningScreen
                ? '${time(s.morningFrom)} – ${time(s.morningTo)}'
                : l10n.morningScreenHint,
          ),
          value: s.morningScreen,
          onChanged: (v) =>
              controller.update((k) => k.copyWith(morningScreen: v)),
        ),
        if (s.morningScreen)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('morningFrom'),
                  onPressed: () async {
                    final m = await pick(s.morningFrom, l10n.morningFrom);
                    if (m != null) {
                      await controller.update(
                        (k) => k.copyWith(morningFrom: m),
                      );
                    }
                  },
                  icon: const Icon(Icons.wb_twilight),
                  label: Text('${l10n.morningFrom} ${time(s.morningFrom)}'),
                ),
                OutlinedButton.icon(
                  key: const Key('morningTo'),
                  onPressed: () async {
                    final m = await pick(s.morningTo, l10n.morningTo);
                    if (m != null) {
                      await controller.update((k) => k.copyWith(morningTo: m));
                    }
                  },
                  icon: const Icon(Icons.wb_sunny_outlined),
                  label: Text('${l10n.morningTo} ${time(s.morningTo)}'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
