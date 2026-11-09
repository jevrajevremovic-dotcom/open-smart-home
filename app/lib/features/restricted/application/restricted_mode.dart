import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/pin_hasher.dart';
import '../../../core/storage/app_preferences.dart';
import '../../devices/domain/device_kind.dart';
import '../../devices/domain/smart_home_device.dart';

/// Child / guest mode for this device: hides sensitive devices and locks
/// settings and adding devices behind a PIN. Local only – Home Assistant
/// permissions are unchanged (use a separate HA user for real limits).
@immutable
class RestrictedSettings {
  const RestrictedSettings({
    this.enabled = false,
    this.hideSecurity = true,
    this.hideCameras = true,
    this.pinHash,
    this.pinSalt,
    this.rooms,
    this.until,
  });

  factory RestrictedSettings.fromJson(Map<String, Object?>? j) =>
      RestrictedSettings(
        enabled: j?['enabled'] == true && j?['pinHash'] is String,
        hideSecurity: j?['hideSecurity'] != false,
        hideCameras: j?['hideCameras'] != false,
        pinHash: j?['pinHash'] as String?,
        pinSalt: j?['pinSalt'] as String?,
        rooms: switch (j?['rooms']) {
          final List<Object?> list => [
            for (final r in list)
              if (r is String) r,
          ],
          _ => null,
        },
        until: DateTime.tryParse('${j?['until']}'),
      );

  final bool enabled;

  /// Locks, alarm panels, garage doors, sirens.
  final bool hideSecurity;
  final bool hideCameras;
  final String? pinHash;
  final String? pinSalt;

  /// A guest sees only these rooms (`null`: every room).
  final List<String>? rooms;

  /// A guest's access ends here; then the app locks until the PIN.
  final DateTime? until;

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'hideSecurity': hideSecurity,
    'hideCameras': hideCameras,
    'pinHash': pinHash,
    'pinSalt': pinSalt,
    'rooms': ?rooms,
    'until': ?until?.toIso8601String(),
  };

  RestrictedSettings copyWith({
    bool? enabled,
    bool? hideSecurity,
    bool? hideCameras,
    String? pinHash,
    String? pinSalt,
    List<String>? rooms,
    bool clearRooms = false,
    DateTime? until,
    bool clearUntil = false,
  }) => RestrictedSettings(
    enabled: enabled ?? this.enabled,
    hideSecurity: hideSecurity ?? this.hideSecurity,
    hideCameras: hideCameras ?? this.hideCameras,
    pinHash: pinHash ?? this.pinHash,
    pinSalt: pinSalt ?? this.pinSalt,
    rooms: clearRooms ? null : rooms ?? this.rooms,
    until: clearUntil ? null : until ?? this.until,
  );

  Set<DeviceKind> get hiddenKinds => !enabled
      ? const {}
      : {
          if (hideSecurity) ...{
            DeviceKind.lock,
            DeviceKind.alarm,
            DeviceKind.garageDoor,
            DeviceKind.siren,
          },
          if (hideCameras) ...{DeviceKind.camera, DeviceKind.doorbell},
        };

  bool hides(SmartHomeDevice d) =>
      hiddenKinds.contains(d.kind) ||
      (enabled && rooms != null && !rooms!.contains(d.roomId));
}

class RestrictedController extends Notifier<RestrictedSettings> {
  static const _key = 'restricted.settings';

  @override
  RestrictedSettings build() => RestrictedSettings.fromJson(
    ref.watch(appPreferencesProvider).readJson(_key),
  );

  Future<void> _save(RestrictedSettings s) async {
    state = s;
    await ref.read(appPreferencesProvider).writeJson(_key, s.toJson());
  }

  Future<void> setOptions({
    bool? hideSecurity,
    bool? hideCameras,
    List<String>? rooms,
    bool clearRooms = false,
    DateTime? until,
    bool clearUntil = false,
  }) => _save(
    state.copyWith(
      hideSecurity: hideSecurity,
      hideCameras: hideCameras,
      rooms: rooms,
      clearRooms: clearRooms,
      until: until,
      clearUntil: clearUntil,
    ),
  );

  /// Turns the mode on with a new PIN (stored only as a PBKDF2 hash); for
  /// a guest, maybe only [rooms] and only until [until].
  Future<void> enable(String pin, {List<String>? rooms, DateTime? until}) {
    final salt = PinHasher.newSalt();
    return _save(
      state.copyWith(
        enabled: true,
        pinSalt: salt,
        pinHash: PinHasher.hash(pin, salt),
        rooms: rooms,
        clearRooms: rooms == null,
        until: until,
        clearUntil: until == null,
      ),
    );
  }

  /// `true` and off when [pin] matches.
  Future<bool> disable(String pin) async {
    final hash = state.pinHash;
    final salt = state.pinSalt;
    if (hash == null || salt == null || !PinHasher.verify(pin, salt, hash)) {
      return false;
    }
    await _save(
      RestrictedSettings(
        hideSecurity: state.hideSecurity,
        hideCameras: state.hideCameras,
      ),
    );
    return true;
  }
}

final restrictedModeProvider =
    NotifierProvider<RestrictedController, RestrictedSettings>(
      RestrictedController.new,
    );

/// A guest's time is up: the app shows only the PIN. Turns true by
/// itself at [RestrictedSettings.until].
final guestExpiredProvider = Provider<bool>((ref) {
  final s = ref.watch(restrictedModeProvider);
  final until = s.until;
  if (!s.enabled || until == null) return false;
  final left = until.difference(DateTime.now());
  if (left <= Duration.zero) return true;
  final timer = Timer(left, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return false;
});
