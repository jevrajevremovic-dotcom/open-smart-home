import 'package:web/web.dart' as web;

import '../errors/app_failure.dart';
import '../logging/app_logger.dart';
import 'credential_store.dart';

CredentialStore createPlatformCredentialStore() =>
    SessionStorageCredentialStore();

/// Browser storage for the access token: the tab's `sessionStorage`.
///
/// Browsers have no hardware-backed secret store comparable to Keychain or
/// Keystore. Encrypting into `localStorage` would keep the key next to the
/// data and needs Web Crypto, which is unavailable on plain-HTTP origins
/// (the usual `http://homeassistant.local:8123`). So the token is kept only
/// for the lifetime of the tab: it is never written to disk long-term and
/// disappears when the tab is closed. Persistent web sign-in is planned via
/// OAuth2 refresh tokens.
class SessionStorageCredentialStore implements CredentialStore {
  static const _prefix = 'ha_access_token::';
  static final _log = AppLogger('CredentialStore');

  web.Storage get _storage => web.window.sessionStorage;

  @override
  Future<String?> readAccessToken(String serverId) async =>
      _guard('read', () => _storage.getItem('$_prefix$serverId'));

  @override
  Future<void> writeAccessToken(String serverId, String token) async =>
      _guard('write', () => _storage.setItem('$_prefix$serverId', token));

  @override
  Future<void> deleteAccessToken(String serverId) async =>
      _guard('delete', () => _storage.removeItem('$_prefix$serverId'));

  @override
  Future<void> deleteAll() async => _guard('deleteAll', () {
    final keys = [for (var i = 0; i < _storage.length; i++) _storage.key(i)]
        .whereType<String>()
        .where((k) => k.startsWith(_prefix))
        .toList();
    for (final key in keys) {
      _storage.removeItem(key);
    }
  });

  T _guard<T>(String op, T Function() action) {
    try {
      return action();
    } on Object catch (e) {
      _log.error('sessionStorage $op failed', e.runtimeType);
      throw AppFailure(
        FailureKind.storage,
        debugMessage: 'sessionStorage $op failed',
      );
    }
  }
}
