import '../../../core/network/server_address.dart';
import '../models/ha_models.dart';

/// Outcome of probing a server before the user has a token.
enum ServerProbeResult {
  /// `GET /api/` answered `401` — a Home Assistant API that requires auth.
  reachableRequiresAuth,

  /// Something answered, but not like the Home Assistant REST API.
  unexpectedResponse,
}

/// Documented Home Assistant REST API (https://developers.home-assistant.io/docs/api/rest/).
///
/// Only endpoints from the official documentation are used here.
abstract interface class HomeAssistantApi {
  ServerAddress get address;

  /// Unauthenticated reachability check. Throws `AppFailure` for network,
  /// timeout and TLS problems.
  Future<ServerProbeResult> probe();

  /// `GET /api/` with the token. Completes normally only for a valid token;
  /// throws `AppFailure` (authentication/authorization/…) otherwise.
  Future<void> verifyAccessToken();

  /// `GET /api/config`.
  Future<HaConfig> fetchConfig();

  /// `GET /api/states`.
  Future<List<HaEntityState>> fetchStates();

  /// `POST /api/services/<domain>/<service>`. Returns states changed while
  /// the service executed.
  Future<List<HaEntityState>> callService(
    String domain,
    String service, {
    Map<String, Object?> data = const {},
  });

  void close();
}
