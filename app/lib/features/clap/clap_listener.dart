import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../devices/application/device_command_service.dart';
import '../devices/application/device_providers.dart';
import '../devices/domain/device_command.dart';
import '../devices/domain/device_kind.dart';
import '../devices/domain/smart_home_device.dart';
import '../devices/presentation/device_presentation.dart';
import '../kiosk/application/kiosk_controller.dart';
import 'clap_detector.dart';
import 'clap_platform.dart';

/// What a double clap may control: things that are harmless to switch by
/// sound. Locks, alarms, garage doors and covers are left out on purpose.
bool isClapTarget(SmartHomeDevice d) =>
    !d.isAuxiliary &&
    (d.kind.isLight ||
        d.kind.isRoutine && d.kind != DeviceKind.automation ||
        const {
          DeviceKind.switchDevice,
          DeviceKind.outlet,
          DeviceKind.fan,
          DeviceKind.airPurifier,
          DeviceKind.humidifier,
          DeviceKind.dehumidifier,
        }.contains(d.kind));

/// Listens for a double clap while the kiosk dashboard is on screen (and
/// nothing covers it, so Assist can use the microphone) and runs the
/// chosen action.
class KioskClapListener extends ConsumerStatefulWidget {
  const KioskClapListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<KioskClapListener> createState() => _KioskClapListenerState();
}

class _KioskClapListenerState extends ConsumerState<KioskClapListener> {
  static final _log = AppLogger('Clap');

  StreamSubscription<double>? _sub;
  ClapDetector? _detector;
  bool _foreground = true;
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onShow: () => _setForeground(true),
    onHide: () => _setForeground(false),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle; // start observing
  }

  void _setForeground(bool v) {
    if (_foreground == v) return;
    setState(() => _foreground = v);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_sub?.cancel());
    super.dispose();
  }

  void _sync({required bool active, required ClapSensitivity sensitivity}) {
    if (!active) {
      if (_sub != null) {
        unawaited(_sub!.cancel());
        _sub = null;
      }
      return;
    }
    if (_sub != null && _detector?.sensitivity == sensitivity) return;
    unawaited(_sub?.cancel());
    final detector = _detector = ClapDetector(sensitivity: sensitivity);
    _sub = ref
        .read(clapPlatformProvider)
        .levels()
        .listen(
          (level) {
            if (detector.add(level)) unawaited(_run());
          },
          onError: (Object e) {
            // E.g. permission withdrawn in system settings.
            _log.warning('microphone unavailable', e.runtimeType);
            _sub = null;
          },
          cancelOnError: true,
        );
  }

  Future<void> _run() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final id = ref.read(kioskSettingsProvider).clapTargetId;
    final device = id == null ? null : ref.read(deviceProvider(id));
    final service = ref.read(deviceCommandServiceProvider);
    if (device == null || service == null || !isClapTarget(device)) return;
    final DeviceCommand command = device.kind.isRoutine
        ? const Activate()
        : device.state.isOn == true
        ? const TurnOff()
        : const TurnOn();
    try {
      await service.execute(device, command);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              device.kind.isRoutine
                  ? l10n.sceneActivated(device.name)
                  : l10n.clapSwitched(
                      device.name,
                      command is TurnOn ? l10n.stateOn : l10n.stateOff,
                    ),
            ),
          ),
        );
    } on Object catch (e) {
      _log.warning('clap action failed', e.runtimeType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(kioskSettingsProvider);
    final platform = ref.watch(clapPlatformProvider);
    // A dialog, sheet or detail screen on top pauses listening.
    final onTop = ModalRoute.of(context)?.isCurrent ?? true;
    final active =
        platform.supported &&
        settings.clapEnabled &&
        settings.clapTargetId != null &&
        ref.watch(kioskActiveProvider) &&
        _foreground &&
        onTop;
    _sync(active: active, sensitivity: settings.clapSensitivity);
    return widget.child;
  }
}

/// Short description of a clap target for settings.
String clapTargetLabel(AppLocalizations l10n, SmartHomeDevice? d) => d == null
    ? l10n.clapTargetNone
    : '${d.name} · ${d.kind.isRoutine ? l10n.svc_activate : l10n.clapToggle}';

IconData clapTargetIcon(SmartHomeDevice? d) =>
    d == null ? Icons.touch_app_outlined : DevicePresentation.icon(d);
