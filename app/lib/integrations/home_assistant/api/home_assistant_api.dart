import 'dart:typed_data';

import '../../../core/network/server_address.dart';
import '../models/ha_calendar.dart';
import '../models/ha_conversation.dart';
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

  /// `POST /api/services/<domain>/<service>?return_response` – for services
  /// that return data (e.g. `weather.get_forecasts`). Returns the
  /// `service_response` object.
  Future<Object?> callServiceForResponse(
    String domain,
    String service, {
    Map<String, Object?> data = const {},
  });

  /// `GET /api/calendars` – calendar entities.
  Future<List<HaCalendar>> fetchCalendars();

  /// `GET /api/calendars/<entity_id>?start=&end=` – events overlapping the
  /// range (expanded recurring events included).
  Future<List<HaCalendarEvent>> fetchCalendarEvents(
    String calendarId,
    DateTime start,
    DateTime end,
  );

  /// `POST /api/conversation/process` – sends a sentence to Assist, which
  /// may control devices with the user's permissions and answers in text.
  Future<HaConversationReply> processConversation(
    String text, {
    String? language,
    String? conversationId,
  });

  /// `GET` of an image served by Home Assistant itself (e.g. a person's
  /// `entity_picture`, `/api/image/serve/...`). Only server-relative
  /// `/api/` paths are accepted, so the token never goes to another host.
  Future<Uint8List> fetchImage(String path);

  void close();
}
