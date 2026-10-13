import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:open_smart_home/core/config/app_config.dart';
import 'package:open_smart_home/core/storage/app_preferences.dart';
import 'package:open_smart_home/core/storage/credential_store.dart';
import 'package:open_smart_home/features/devices/data/cache/snapshot_cache.dart';
import 'package:open_smart_home/features/kiosk/application/kiosk_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory replacement for the platform keychain/keystore.
class InMemoryCredentialStore implements CredentialStore {
  final Map<String, String> values = {};

  @override
  Future<String?> readAccessToken(String serverId) async => values[serverId];

  @override
  Future<void> writeAccessToken(String serverId, String token) async =>
      values[serverId] = token;

  @override
  Future<void> deleteAccessToken(String serverId) async =>
      values.remove(serverId);

  @override
  Future<void> deleteAll() async => values.clear();
}

/// Records kiosk platform calls instead of touching platform channels.
class FakeKioskPlatform implements KioskPlatform {
  bool fullscreen = false;
  bool screenOn = false;

  @override
  Future<void> enterFullscreen() async => fullscreen = true;

  @override
  Future<void> exitFullscreen() async => fullscreen = false;

  @override
  Future<void> keepScreenOn(bool on) async => screenOn = on;
}

/// Overrides for running the app against the in-memory mock server.
Future<List<Override>> testOverrides({
  InMemoryCredentialStore? credentials,
  KioskPlatform? kioskPlatform,
  SnapshotCache? snapshotCache,
  Map<String, Object> preferences = const {},
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  final prefs = await SharedPreferences.getInstance();
  return [
    appConfigProvider.overrideWithValue(const AppConfig(mockMode: true)),
    sharedPreferencesProvider.overrideWithValue(prefs),
    snapshotCacheProvider.overrideWithValue(
      snapshotCache ?? InMemorySnapshotCache(),
    ),
    kioskPlatformProvider.overrideWithValue(
      kioskPlatform ?? FakeKioskPlatform(),
    ),
    credentialStoreProvider.overrideWithValue(
      credentials ?? InMemoryCredentialStore(),
    ),
  ];
}
