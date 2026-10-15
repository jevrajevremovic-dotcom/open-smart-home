import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/domain/device_kind.dart';
import '../../devices/presentation/device_presentation.dart';
import '../application/kiosk_controller.dart';
import '../data/kiosk_settings.dart';
import 'camera_popup.dart';

/// Settings row for the kiosk camera pop-up.
class CameraPopupSettingsTile extends ConsumerWidget {
  const CameraPopupSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(kioskSettingsProvider);
    final camera = s.popupCameraId == null
        ? null
        : ref.watch(deviceProvider(s.popupCameraId!));
    return ListTile(
      key: const Key('kioskPopup'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.doorbell_outlined),
      title: Text(l10n.kioskPopup),
      subtitle: Text(
        s.hasPopup && camera != null
            ? l10n.kioskPopupSummary(camera.name, s.popupTriggerIds.length)
            : l10n.kioskPopupHint,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => const _CameraPopupDialog(),
      ),
    );
  }
}

class _CameraPopupDialog extends ConsumerStatefulWidget {
  const _CameraPopupDialog();

  @override
  ConsumerState<_CameraPopupDialog> createState() => _CameraPopupDialogState();
}

class _CameraPopupDialogState extends ConsumerState<_CameraPopupDialog> {
  late final KioskSettings _initial = ref.read(kioskSettingsProvider);
  late String? _camera = _initial.popupCameraId;
  late final Set<String> _triggers = {..._initial.popupTriggerIds};
  late int _seconds = _initial.popupSeconds;

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    await ref
        .read(kioskSettingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            popupCameraId: _camera,
            clearPopupCamera: _camera == null,
            popupTriggerIds: _triggers.toList(),
            popupSeconds: _seconds,
          ),
        );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
    final cameras =
        devices.values.where((d) => d.kind == DeviceKind.camera).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final triggers = devices.values.where(isPopupTrigger).toList()
      ..sort((a, b) {
        // Doorbells first: the usual reason for a pop-up.
        final da = a.kind == DeviceKind.doorbell ? 0 : 1;
        final db = b.kind == DeviceKind.doorbell ? 0 : 1;
        return da != db ? da - db : a.name.compareTo(b.name);
      });
    return AlertDialog(
      title: Text(l10n.kioskPopup),
      content: SizedBox(
        width: 460,
        height: 520,
        child: ListView(
          children: [
            Text(l10n.kioskPopupExplain, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              key: const Key('kioskPopupCamera'),
              initialValue: _camera,
              decoration: InputDecoration(labelText: l10n.kioskPopupCamera),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.kioskPopupOff)),
                for (final c in cameras)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _camera = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: const Key('kioskPopupSeconds'),
              initialValue: _seconds,
              decoration: InputDecoration(labelText: l10n.kioskPopupDuration),
              items: [
                for (final s in KioskSettings.popupOptions)
                  DropdownMenuItem(
                    value: s,
                    child: Text(
                      s < 60
                          ? l10n.durationSeconds(s)
                          : l10n.durationMinutes(s ~/ 60),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _seconds = v ?? _seconds),
            ),
            const SizedBox(height: 16),
            Text(l10n.kioskPopupTriggers, style: theme.textTheme.titleSmall),
            for (final d in triggers)
              CheckboxListTile(
                key: ValueKey('kioskPopupTrigger-${d.id}'),
                contentPadding: EdgeInsets.zero,
                secondary: Icon(DevicePresentation.icon(d)),
                title: Text(d.name),
                value: _triggers.contains(d.id),
                onChanged: (v) => setState(
                  () =>
                      v == true ? _triggers.add(d.id) : _triggers.remove(d.id),
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
          key: const Key('kioskPopupSave'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
