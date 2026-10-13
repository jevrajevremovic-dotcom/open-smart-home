import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_preferences.dart';
import '../../../core/storage/credential_store.dart';
import '../../devices/data/cache/snapshot_cache.dart';
import '../domain/stored_credential.dart';
import 'server_profile.dart';

/// Persists which server the app is connected to and its access token.
class SessionRepository {
  SessionRepository(this._preferences, this._credentials, this._cache);

  final AppPreferences _preferences;
  final CredentialStore _credentials;
  final SnapshotCache _cache;

  /// The stored profile, but only if a valid credential for it also exists.
  Future<ServerProfile?> loadProfile() async {
    final profile = ServerProfile.tryFromJson(_preferences.serverProfileJson);
    if (profile == null) return null;
    final credential = StoredCredential.parse(
      await _credentials.readCredential(profile.id),
    );
    return credential == null ? null : profile;
  }

  Future<void> save(ServerProfile profile, StoredCredential credential) async {
    // Credential first: a profile without one is treated as signed-out.
    await _credentials.writeCredential(
      profile.id,
      credential.serialize(),
      persistent: credential.persistent,
    );
    await _preferences.setServerProfileJson(profile.toJson());
  }

  /// Removes the token and the server profile; keeps theme and language.
  Future<void> signOut(ServerProfile? profile) async {
    if (profile != null) {
      await _credentials.deleteCredential(profile.id);
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
