import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:open_smart_home/core/config/app_config.dart';
import 'package:open_smart_home/core/platform/browser_port.dart';
import 'package:open_smart_home/core/storage/app_preferences.dart';
import 'package:open_smart_home/core/storage/credential_store.dart';
import 'package:open_smart_home/features/devices/data/cache/snapshot_cache.dart';
import 'package:open_smart_home/features/kiosk/application/kiosk_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory replacement for the platform keychain/keystore.
class InMemoryCredentialStore implements CredentialStore {
  final Map<String, String> values = {};

  @override
  Future<String?> readCredential(String serverId) async => values[serverId];

  @override
  Future<void> writeCredential(
    String serverId,
    String value, {
    bool persistent = false,
  }) async => values[serverId] = value;

  @override
  Future<void> deleteCredential(String serverId) async =>
      values.remove(serverId);

  @override
  Future<void> deleteAll() async => values.clear();
}

/// A scriptable browser for testing the web sign-in on the VM.
class FakeBrowserPort implements BrowserPort {
  FakeBrowserPort(this.currentUrl);

  @override
  Uri currentUrl;
  final Map<String, String> session = {};
  final List<Uri> navigations = [];

  @override
  bool get isAvailable => true;

  @override
  String? sessionGet(String key) => session[key];

  @override
  void sessionSet(String key, String value) => session[key] = value;

  @override
  void sessionRemove(String key) => session.remove(key);

  @override
  void navigate(Uri url) => navigations.add(url);

  @override
  void replaceUrl(Uri url) => currentUrl = url;
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
