import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'credential_store_io.dart'
    if (dart.library.js_interop) 'credential_store_web.dart';

/// Secret storage for access tokens. Values never leave this class except to
/// the HTTP/WebSocket layer that needs them.
///
/// * Android / iOS: Keychain / Keystore (`credential_store_io.dart`).
/// * Web: the tab's `sessionStorage` (`credential_store_web.dart`).
abstract interface class CredentialStore {
  Future<String?> readAccessToken(String serverId);
  Future<void> writeAccessToken(String serverId, String token);
  Future<void> deleteAccessToken(String serverId);
  Future<void> deleteAll();
}

final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => createPlatformCredentialStore(),
);
