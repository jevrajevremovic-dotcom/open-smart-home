import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../assist/presentation/wake_word_settings.dart';
import '../../clap/clap_settings.dart';
import 'approach_settings.dart';
import '../application/kiosk_controller.dart';
import '../data/kiosk_settings.dart';
import 'camera_popup_settings.dart';
import 'glass.dart';
import 'kiosk_layout_view.dart';
import 'aod_settings.dart';
import 'night_brightness_settings.dart';
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
        ListTile(
          key: const Key('kioskEditLayoutTile'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.dashboard_customize_outlined),
          title: Text(l10n.kioskEditLayout),
          subtitle: Text(l10n.kioskEditLayoutHint),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ref.read(kioskActiveProvider.notifier).enter();
            ref.read(kioskEditingProvider.notifier).set(true);
            context.go(AppRoutes.kiosk);
          },
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.kioskStyle),
              const SizedBox(height: 8),
              SegmentedButton<KioskStyle>(
                key: const Key('kioskStyle'),
                segments: [
                  ButtonSegment(
                    value: KioskStyle.bubble,
                    icon: const Icon(Icons.bubble_chart_outlined),
                    label: Text(l10n.kioskStyleBubble),
                  ),
                  ButtonSegment(
                    value: KioskStyle.glass,
                    icon: const Icon(Icons.blur_on),
                    label: Text(l10n.kioskStyleGlass),
                  ),
                ],
                selected: {settings.style},
                onSelectionChanged: (v) =>
                    controller.update((s) => s.copyWith(style: v.first)),
              ),
            ],
          ),
        ),
        // The gradient belongs to the glass style.
        if (!settings.bubble)
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
        if (ref.watch(kioskPhotoStoreProvider).supported)
          ListTile(
            key: const Key('kioskPhoto'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.kioskPhoto),
            subtitle: Text(l10n.kioskPhotoHint),
            trailing: settings.photoPath == null
                ? TextButton(
                    key: const Key('kioskPhotoPick'),
                    onPressed: () => _pickPhoto(ref),
                    child: Text(l10n.kioskPhotoPick),
                  )
                : TextButton(
                    key: const Key('kioskPhotoRemove'),
                    onPressed: () async {
                      final path = settings.photoPath!;
                      await controller.update(
                        (s) => s.copyWith(clearPhoto: true),
                      );
                      await ref.read(kioskPhotoStoreProvider).delete(path);
                    },
                    child: Text(l10n.kioskPhotoRemove),
                  ),
          ),
        SwitchListTile(
          key: const Key('kioskShowCameras'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.kioskShowCameras),
          subtitle: Text(l10n.kioskShowCamerasHint),
          value: settings.showCameras,
          onChanged: (v) =>
              controller.update((s) => s.copyWith(showCameras: v)),
        ),
        SwitchListTile(
          key: const Key('kioskShowCalendar'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.kioskShowCalendar),
          subtitle: Text(l10n.kioskShowCalendarHint),
          value: settings.showCalendar,
          onChanged: (v) =>
              controller.update((s) => s.copyWith(showCalendar: v)),
        ),
        const CameraPopupSettingsTile(),
        const ClapSettings(),
        const WakeWordSettings(),
        const ApproachSettings(),
        SwitchListTile(
          key: const Key('kioskGreetSwitch'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.waving_hand_outlined),
          title: Text(l10n.greetPeople),
          subtitle: Text(l10n.greetPeopleHint),
          value: settings.greetPeople,
          onChanged: (v) =>
              controller.update((s) => s.copyWith(greetPeople: v)),
        ),
        SwitchListTile(
          key: const Key('kioskAlertSwitch'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.crisis_alert_rounded),
          title: Text(l10n.kioskAlertSetting),
          subtitle: Text(l10n.kioskAlertSettingHint),
          value: settings.alertOverlay,
          onChanged: (v) =>
              controller.update((s) => s.copyWith(alertOverlay: v)),
        ),
        if (settings.alertOverlay)
          ListTile(
            contentPadding: const EdgeInsets.only(left: 40),
            title: Text(l10n.kioskOpenAlert),
            trailing: DropdownButton<int>(
              key: const Key('kioskOpenAlert'),
              value: settings.openAlertMinutes,
              onChanged: (v) => v == null
                  ? null
                  : controller.update((s) => s.copyWith(openAlertMinutes: v)),
              items: [
                for (final m in {
                  0,
                  5,
                  10,
                  15,
                  30,
                  60,
                  settings.openAlertMinutes,
                })
                  DropdownMenuItem(
                    value: m,
                    child: Text(
                      m == 0
                          ? l10n.kioskOpenAlertNever
                          : l10n.kioskOpenAlertMinutes(m),
                    ),
                  ),
              ],
            ),
          ),
        if (!settings.bubble)
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
        const AodSettings(),
        const NightBrightnessSettings(),
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

/// Lets tests replace the system photo picker.
final kioskPhotoPickerProvider = Provider<Future<Uint8List?> Function()>(
  (ref) => () async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2560,
      maxHeight: 2560,
      imageQuality: 85,
    );
    return file?.readAsBytes();
  },
);

Future<void> _pickPhoto(WidgetRef ref) async {
  final bytes = await ref.read(kioskPhotoPickerProvider)();
  if (bytes == null) return;
  final store = ref.read(kioskPhotoStoreProvider);
  final path = await store.save(bytes);
  final old = ref.read(kioskSettingsProvider).photoPath;
  await ref
      .read(kioskSettingsProvider.notifier)
      .update((s) => s.copyWith(photoPath: path));
  if (old != null) await store.delete(old);
}
