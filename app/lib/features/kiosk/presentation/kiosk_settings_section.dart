import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../../core/widgets/status_widgets.dart';
import '../application/kiosk_controller.dart';
import '../data/kiosk_settings.dart';
import 'pin_dialog.dart';
import 'status_entities_picker.dart';

/// Kiosk options inside the settings screen.
class KioskSettingsSection extends ConsumerWidget {
  const KioskSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(kioskSettingsProvider);
    final controller = ref.read(kioskSettingsProvider.notifier);

    String label(Duration d) => d == Duration.zero
        ? l10n.durationNever
        : d.inSeconds < 60
        ? l10n.durationSeconds(d.inSeconds)
        : l10n.durationMinutes(d.inMinutes);

    Widget durationPicker({
      required Key key,
      required String title,
      required Duration value,
      required List<Duration> options,
      required void Function(Duration) onChanged,
    }) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: DropdownButton<Duration>(
        key: key,
        value: options.contains(value) ? value : options.first,
        items: [
          for (final o in options)
            DropdownMenuItem(value: o, child: Text(label(o))),
        ],
        onChanged: (v) => v == null ? null : onChanged(v),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const Key('startKiosk'),
          onPressed: () {
            ref.read(kioskActiveProvider.notifier).enter();
            context.go(AppRoutes.kiosk);
          },
          icon: const Icon(Icons.tablet_outlined),
          label: Text(l10n.kioskStart),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.kioskStartOnLaunch),
          value: settings.startInKiosk,
          onChanged: (v) =>
              controller.update((s) => s.copyWith(startInKiosk: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.kioskKeepAwake),
          value: settings.keepScreenOn,
          onChanged: (v) =>
              controller.update((s) => s.copyWith(keepScreenOn: v)),
        ),
        ListTile(
          key: const Key('kioskStatusEntities'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.kioskStatusEntities),
          subtitle: Text(
            settings.statusEntityIds.isEmpty
                ? l10n.kioskStatusNone
                : l10n.kioskStatusSelected(settings.statusEntityIds.length),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final picked = await showStatusEntitiesPicker(
              context,
              settings.statusEntityIds,
            );
            if (picked != null) {
              await controller.update(
                (s) => s.copyWith(statusEntityIds: picked),
              );
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.kioskBackground),
          trailing: DropdownButton<KioskBackground>(
            key: const Key('kioskBackground'),
            value: settings.background,
            items: [
              for (final b in KioskBackground.values)
                DropdownMenuItem(
                  value: b,
                  child: Text(switch (b) {
                    KioskBackground.aurora => l10n.kioskBackgroundAurora,
                    KioskBackground.ocean => l10n.kioskBackgroundOcean,
                    KioskBackground.dusk => l10n.kioskBackgroundDusk,
                    KioskBackground.forest => l10n.kioskBackgroundForest,
                  }),
                ),
            ],
            onChanged: (v) => v == null
                ? null
                : controller.update((s) => s.copyWith(background: v)),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.kioskLiteEffects),
          subtitle: Text(l10n.kioskLiteEffectsHint),
          value: settings.liteEffects,
          onChanged: (v) =>
              controller.update((s) => s.copyWith(liteEffects: v)),
        ),
        durationPicker(
          key: const Key('kioskDimAfter'),
          title: l10n.kioskDimAfter,
          value: settings.dimAfter,
          options: KioskSettings.dimOptions,
          onChanged: (v) => controller.update((s) => s.copyWith(dimAfter: v)),
        ),
        durationPicker(
          key: const Key('kioskReturnAfter'),
          title: l10n.kioskReturnAfter,
          value: settings.returnHomeAfter,
          options: KioskSettings.returnOptions,
          onChanged: (v) =>
              controller.update((s) => s.copyWith(returnHomeAfter: v)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            settings.hasPin ? Icons.lock_outline : Icons.lock_open_outlined,
          ),
          title: Text(l10n.kioskPin),
          subtitle: Text(
            settings.hasPin ? l10n.kioskPinSet : l10n.kioskPinNotSet,
          ),
          trailing: Wrap(
            spacing: 4,
            children: [
              TextButton(
                key: const Key('kioskSetPin'),
                onPressed: () => showSetPinDialog(context, ref),
                child: Text(
                  settings.hasPin ? l10n.kioskChangePin : l10n.kioskSetPin,
                ),
              ),
              if (settings.hasPin)
                TextButton(
                  onPressed: controller.removePin,
                  child: Text(l10n.kioskRemovePin),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InlineNotice.info(l10n.kioskOsHint),
      ],
    );
  }
}
