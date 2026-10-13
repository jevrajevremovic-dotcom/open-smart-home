import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../integrations/home_assistant/api/home_assistant_api.dart';
import '../../../integrations/home_assistant/home_assistant_providers.dart';
import '../../../integrations/home_assistant/models/ha_models.dart';
import '../../../integrations/home_assistant/websocket/connection_status.dart';
import '../../../integrations/home_assistant/websocket/ha_websocket_manager.dart';
import '../data/server_profile.dart';
import '../data/session_repository.dart';

/// The signed-in state. `null` in [SessionController] means signed out.
@immutable
class Session {
  const Session(this.profile);
  final ServerProfile profile;
}

class SessionController extends AsyncNotifier<Session?> {
  static final _log = AppLogger('Session');

  SessionRepository get _repository => ref.read(sessionRepositoryProvider);

  @override
  Future<Session?> build() async {
    final profile = await _repository.loadProfile();
    return profile == null ? null : Session(profile);
  }

  /// Persists a profile whose token was already verified by the caller.
  Future<void> signIn(ServerProfile profile, String token) async {
    await _repository.save(profile, token);
    _log.info('Signed in to ${profile.address.host}');
    state = AsyncData(Session(profile));
  }

  /// Closes connections and deletes the stored token.
  Future<void> signOut() async {
    final profile = state.value?.profile;
    state = const AsyncData(null); // disposes session-scoped providers
    await _repository.signOut(profile);
    _log.info('Signed out');
  }

  /// Signs out and wipes every local value, including theme and language.
  Future<void> deleteAllLocalData() async {
    state = const AsyncData(null);
    await _repository.deleteAllLocalData();
    _log.info('All local data deleted');
  }
}

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, Session?>(SessionController.new);

/// The active server profile, or `null` when signed out.
final activeProfileProvider = Provider<ServerProfile?>(
  (ref) => ref.watch(sessionControllerProvider).value?.profile,
);

/// REST client for the active session.
final homeAssistantApiProvider = Provider<HomeAssistantApi?>((ref) {
  final profile = ref.watch(activeProfileProvider);
  if (profile == null) return null;
  final repository = ref.watch(sessionRepositoryProvider);
  final api = ref.watch(homeAssistantApiFactoryProvider)(
    profile,
    () => repository.readToken(profile),
  );
  ref.onDispose(api.close);
  return api;
});

/// The WebSocket manager lives exactly as long as the session.
final webSocketManagerProvider = Provider<HaWebSocketManager?>((ref) {
  final profile = ref.watch(activeProfileProvider);
  if (profile == null) return null;
  final repository = ref.watch(sessionRepositoryProvider);
  final manager = HaWebSocketManager(
    uri: profile.address.webSocketUri,
    readToken: () => repository.readToken(profile),
    connector: ref.watch(haSocketConnectorFactoryProvider)(profile.tlsTrust),
  )..connect();
  ref.onDispose(() => unawaited(manager.dispose()));
  return manager;
});

final connectionStatusProvider = StreamProvider<HaConnectionStatus>((
  ref,
) async* {
  final manager = ref.watch(webSocketManagerProvider);
  if (manager == null) {
    yield HaConnectionStatus.initial;
    return;
  }
  yield manager.status;
  yield* manager.statusStream;
});

/// `GET /api/config` for the active session.
final serverConfigProvider = FutureProvider<HaConfig?>((ref) async {
  final api = ref.watch(homeAssistantApiProvider);
  return api?.fetchConfig();
});
