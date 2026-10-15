import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../../cameras/presentation/camera_view.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/data/home_state_repository.dart';
import '../../devices/domain/device_kind.dart';
import '../../devices/domain/smart_home_device.dart';
import '../application/kiosk_controller.dart';

/// Devices that may pop up the camera: a doorbell, or something that turns
/// "on" (motion, presence, a door or gate contact).
bool isPopupTrigger(SmartHomeDevice d) =>
    !d.isAuxiliary &&
    (d.kind == DeviceKind.doorbell ||
        const {
          DeviceKind.motionSensor,
          DeviceKind.occupancySensor,
          DeviceKind.contactSensor,
          DeviceKind.binarySensor,
          DeviceKind.vibrationSensor,
        }.contains(d.kind));

/// What counts as "it happened" for a trigger: a doorbell press (its time
/// changes) or a sensor turning on.
Object? _signal(SmartHomeDevice? d) => switch (d) {
  null => null,
  _ when !d.available => null,
  _ when d.kind == DeviceKind.doorbell => d.state.lastTriggered,
  _ => d.state.isActive == true,
};

/// Watches the chosen triggers and shows the chosen camera full screen
/// over any kiosk page; [onShow] wakes the screen.
class KioskCameraPopup extends ConsumerStatefulWidget {
  const KioskCameraPopup({
    super.key,
    required this.child,
    required this.onShow,
  });

  final Widget child;
  final VoidCallback onShow;

  @override
  ConsumerState<KioskCameraPopup> createState() => _KioskCameraPopupState();
}

class _KioskCameraPopupState extends ConsumerState<KioskCameraPopup> {
  String? _triggerName;
  Timer? _hide;
  int _left = 0;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _show(String triggerName) {
    final seconds = ref.read(kioskSettingsProvider).popupSeconds;
    widget.onShow();
    setState(() {
      _triggerName = triggerName;
      _left = seconds;
    });
    _hide?.cancel();
    _hide = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _left--);
      if (_left <= 0) _close();
    });
  }

  void _close() {
    _hide?.cancel();
    if (mounted) setState(() => _triggerName = null);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(kioskSettingsProvider);
    final cameraId = settings.popupCameraId;
    if (settings.hasPopup) {
      ref.listen<Map<String, Object?>>(
        homeSnapshotProvider.select(
          (s) => {
            for (final id in settings.popupTriggerIds)
              id: _signal(s.devices[id]),
          },
        ),
        (previous, next) {
          // Only live changes: not the cached state shown at start-up.
          if (previous == null ||
              ref.read(syncStatusProvider) != SyncStatus.live) {
            return;
          }
          for (final id in settings.popupTriggerIds) {
            final before = previous[id];
            final now = next[id];
            final fired = now is DateTime
                ? before is DateTime && now.isAfter(before)
                : now == true && before == false;
            if (fired) {
              _show(ref.read(deviceProvider(id))?.name ?? id);
              return;
            }
          }
        },
      );
    }
    final l10n = context.l10n;
    return Stack(
      children: [
        widget.child,
        if (_triggerName != null && cameraId != null)
          Positioned.fill(
            child: ColoredBox(
              key: const Key('kioskCameraPopup'),
              color: Colors.black,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 8, 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_active,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _triggerName!,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                          Text(
                            l10n.kioskPopupClosesIn(_left),
                            style: const TextStyle(color: Colors.white54),
                          ),
                          IconButton(
                            key: const Key('kioskPopupClose'),
                            tooltip: l10n.close,
                            color: Colors.white,
                            iconSize: 32,
                            icon: const Icon(Icons.close),
                            onPressed: _close,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: CameraPicture(
                            cameraId: cameraId,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
