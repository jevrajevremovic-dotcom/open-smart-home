import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_preferences.dart';
import '../../../core/storage/credential_store.dart';
import '../../devices/data/cache/snapshot_cache.dart';
import 'server_profile.dart';

/// Persists which server the app is connected to and its access token.
class SessionRepository {
  SessionRepository(this._preferences, this._credentials, this._cache);

  final AppPreferences _preferences;
  final CredentialStore _credentials;
  final SnapshotCache _cache;

  /// The stored profile, but only if a token for it also exists.
  Future<ServerProfile?> loadProfile() async {
    final profile = ServerProfile.tryFromJson(_preferences.serverProfileJson);
    if (profile == null) return null;
    final token = await _credentials.readAccessToken(profile.id);
    return (token == null || token.isEmpty) ? null : profile;
  }

  Future<String?> readToken(ServerProfile profile) =>
      _credentials.readAccessToken(profile.id);

  Future<void> save(ServerProfile profile, String token) async {
    // Token first: a profile without a token is treated as signed-out.
    await _credentials.writeAccessToken(profile.id, token);
    await _preferences.setServerProfileJson(profile.toJson());
  }

  /// Removes the token and the server profile; keeps theme and language.
  Future<void> signOut(ServerProfile? profile) async {
    if (profile != null) {
      await _credentials.deleteAccessToken(profile.id);
      await _cache.clear(profile.id);
    }
    await _preferences.setServerProfileJson(null);
  }

  /// Removes every locally stored value, secrets included.
  Future<void> deleteAllLocalData() async {
    await _credentials.deleteAll();
    await _cache.clearAll();
    await _preferences.clear();
  }
}

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(
    ref.watch(appPreferencesProvider),
    ref.watch(credentialStoreProvider),
    ref.watch(snapshotCacheProvider),
  ),
);
