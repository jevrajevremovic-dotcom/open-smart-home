import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../application/kiosk_controller.dart';

/// Kiosk brightness options: lower at night, minimum on the screensaver.
class NightBrightnessSettings extends ConsumerWidget {
  const NightBrightnessSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(kioskSettingsProvider);
    final controller = ref.read(kioskSettingsProvider.notifier);
    String time(int minutes) =>
        TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);

    Future<int?> pick(int current, String help) async {
      final t = await showTimePicker(
        context: context,
        helpText: help,
        initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      );
      return t == null ? null : t.hour * 60 + t.minute;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('kioskDarkScreensaver'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.kioskDarkScreensaver),
          subtitle: Text(l10n.kioskDarkScreensaverHint),
          value: s.darkScreensaver,
          onChanged: (v) =>
              controller.update((k) => k.copyWith(darkScreensaver: v)),
        ),
        SwitchListTile(
          key: const Key('kioskNight'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.kioskNight),
          subtitle: Text(
            s.nightBrightness
                ? l10n.kioskNightRange(time(s.nightFrom), time(s.nightTo))
                : l10n.kioskNightHint,
          ),
          value: s.nightBrightness,
          onChanged: (v) =>
              controller.update((k) => k.copyWith(nightBrightness: v)),
        ),
        if (s.nightBrightness) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('kioskNightFrom'),
                  icon: const Icon(Icons.bedtime_outlined),
                  label: Text(l10n.kioskNightFrom(time(s.nightFrom))),
                  onPressed: () async {
                    final m = await pick(s.nightFrom, l10n.kioskNightFromHelp);
                    if (m != null) {
                      await controller.update((k) => k.copyWith(nightFrom: m));
                    }
                  },
                ),
                OutlinedButton.icon(
                  key: const Key('kioskNightTo'),
                  icon: const Icon(Icons.wb_sunny_outlined),
                  label: Text(l10n.kioskNightTo(time(s.nightTo))),
                  onPressed: () async {
                    final m = await pick(s.nightTo, l10n.kioskNightToHelp);
                    if (m != null) {
                      await controller.update((k) => k.copyWith(nightTo: m));
                    }
                  },
                ),
              ],
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.only(left: 16),
            title: Text(l10n.kioskNightLevel((s.nightLevel * 100).round())),
            subtitle: Slider(
              key: const Key('kioskNightLevel'),
              value: s.nightLevel,
              min: 0.02,
              max: 0.6,
              divisions: 29,
              onChanged: (v) =>
                  controller.update((k) => k.copyWith(nightLevel: v)),
            ),
          ),
        ],
      ],
    );
  }
}
