import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/security/pin_hasher.dart';
import '../../../core/storage/app_preferences.dart';
import '../../authentication/application/session_controller.dart';
import '../data/kiosk_settings.dart';

class KioskSettingsController extends Notifier<KioskSettings> {
  @override
  KioskSettings build() => KioskSettings.fromJson(
    ref.watch(appPreferencesProvider).kioskSettingsJson,
  );

  Future<void> update(KioskSettings Function(KioskSettings) change) async {
    state = change(state);
    await ref.read(appPreferencesProvider).setKioskSettingsJson(state.toJson());
  }

  /// Returns `false` when [pin] is not 4–8 digits.
  Future<bool> setPin(String pin) async {
    if (!PinHasher.validPin.hasMatch(pin)) return false;
    final salt = PinHasher.newSalt();
    // ~tens of ms once per PIN change; not worth an isolate.
    final hash = PinHasher.hash(pin, salt);
    await update((s) => s.copyWith(pinHash: hash, pinSalt: salt));
    return true;
  }

  Future<void> removePin() => update((s) => s.copyWith(clearPin: true));
}

final kioskSettingsProvider =
    NotifierProvider<KioskSettingsController, KioskSettings>(
      KioskSettingsController.new,
    );

/// Result of an exit attempt.
enum PinCheck { accepted, wrong, lockedOut }

/// Whether kiosk mode is active. While it is, the router keeps the user on
/// kiosk routes; leaving requires the PIN (if one is set).
class KioskSessionController extends Notifier<bool> {
  static final _log = AppLogger('Kiosk');

  static const maxAttempts = 5;
  static const lockout = Duration(seconds: 30);

  int _failures = 0;
  DateTime? _lockedUntil;

  /// Injectable clock for tests.
  @visibleForTesting
  DateTime Function() now = DateTime.now;

  @override
  bool build() {
    // Signing out (or wiping data) always leaves kiosk mode.
    ref.listen(sessionControllerProvider, (previous, next) {
      if (previous?.value != null && next.value == null) state = false;
    });
    return ref.read(kioskSettingsProvider).startInKiosk;
  }

  void enter() {
    _log.info('Entering kiosk mode');
    state = true;
  }

  Duration? get remainingLockout {
    final until = _lockedUntil;
    if (until == null) return null;
    final left = until.difference(now());
    return left.isNegative ? null : left;
  }

  /// Leaves kiosk mode when [pin] matches (or no PIN is configured).
  Future<PinCheck> tryExit(String pin) async {
    if (remainingLockout != null) return PinCheck.lockedOut;
    final settings = ref.read(kioskSettingsProvider);
    final ok =
        !settings.hasPin ||
        PinHasher.verify(pin, settings.pinSalt!, settings.pinHash!);
    if (ok) {
      _failures = 0;
      _lockedUntil = null;
      state = false;
      _log.info('Left kiosk mode');
      return PinCheck.accepted;
    }
    _failures++;
    _log.warning('Wrong kiosk PIN ($_failures/$maxAttempts)');
    if (_failures >= maxAttempts) {
      _failures = 0;
      _lockedUntil = now().add(lockout);
      return PinCheck.lockedOut;
    }
    return PinCheck.wrong;
  }

  /// Leaves kiosk mode without a PIN — only for sign-out / data wipe.
  void forceExit() => state = false;
}

final kioskActiveProvider = NotifierProvider<KioskSessionController, bool>(
  KioskSessionController.new,
);

/// `true` while the kiosk screensaver covers the screen; cameras stop
/// refreshing then.
final kioskDimmedProvider = NotifierProvider<KioskDimmedController, bool>(
  KioskDimmedController.new,
);

class KioskDimmedController extends Notifier<bool> {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void set(bool dimmed) => state = dimmed;
}

/// Platform side effects of kiosk mode, behind an interface so widget tests
/// do not touch platform channels.
abstract interface class KioskPlatform {
  Future<void> enterFullscreen();
  Future<void> exitFullscreen();
  Future<void> keepScreenOn(bool on);
}

class DefaultKioskPlatform implements KioskPlatform {
  static final _log = AppLogger('KioskPlatform');

  @override
  Future<void> enterFullscreen() => _safe(
    'fullscreen',
    () => SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
  );

  @override
  Future<void> exitFullscreen() => _safe(
    'fullscreen',
    () => SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
  );

  @override
  Future<void> keepScreenOn(bool on) =>
      _safe('wakelock', () => WakelockPlus.toggle(enable: on));

  // Unsupported platforms (e.g. web on plain HTTP has no Wake Lock API)
  // must not break kiosk mode.
  Future<void> _safe(String what, Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e) {
      _log.warning('$what not available on this platform', e.runtimeType);
    }
  }
}

final kioskPlatformProvider = Provider<KioskPlatform>(
  (ref) => DefaultKioskPlatform(),
);
