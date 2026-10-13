import 'dart:async';
import 'dart:convert';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/server_address.dart';
import '../api/home_assistant_api.dart';
import '../models/ha_models.dart';
import '../websocket/ha_socket.dart';
import 'mock_fixtures.dart';

/// Token that the mock server rejects, to exercise the auth-failure path.
const String mockInvalidToken = 'invalid';

/// An in-memory Home Assistant: entity states, a minimal service
/// implementation, and the WebSocket protocol. Both the mock REST API and
/// mock sockets talk to the same instance, so a service call made over REST
/// produces `state_changed` events on the WebSocket, as on a real server.
class MockHomeAssistantServer {
  MockHomeAssistantServer({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    for (final s in buildMockStates(_clock())) {
      _states[s['entity_id']! as String] = s;
    }
  }

  static const String version = '2026.10.0-mock';

  final DateTime Function() _clock;
  final Map<String, Map<String, Object?>> _states = {};
  final Set<_MockSocket> _sockets = {};

  final registries = buildMockRegistries();

  /// Artificial latency for `get_states`, to exercise events that arrive
  /// while a snapshot is loading.
  Duration getStatesDelay = Duration.zero;

  /// Sends a bare bus event (e.g. `entity_registry_updated`) to subscribers.
  void fireEvent(String eventType, [Map<String, Object?> data = const {}]) {
    final event = {
      'event_type': eventType,
      'data': data,
      'origin': 'LOCAL',
      'time_fired': _clock().toUtc().toIso8601String(),
    };
    for (final socket in _sockets) {
      socket._dispatchEvent(event);
    }
  }

  /// When false, new connections fail as if the server were down.
  bool online = true;

  bool acceptsToken(String? token) =>
      token != null && token.isNotEmpty && token != mockInvalidToken;

  List<Map<String, Object?>> get states => _states.values.toList();

  Future<HaSocket> connect(Uri uri) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!online) {
      throw const AppFailure(
        FailureKind.network,
        debugMessage: 'mock server offline',
      );
    }
    final socket = _MockSocket(this);
    _sockets.add(socket);
    scheduleMicrotask(
      () => socket._emit({'type': 'auth_required', 'ha_version': version}),
    );
    return socket;
  }

  /// Simulates a server restart: drops every open connection.
  Future<void> dropAllConnections() async {
    for (final socket in _sockets.toList()) {
      await socket._serverClose();
    }
  }

  /// Applies a subset of real Home Assistant services to the mock state.
  List<Map<String, Object?>> callService(
    String domain,
    String service,
    Map<String, Object?> data,
  ) {
    final ids = switch (data['entity_id']) {
      final String id => [id],
      final List<Object?> list => list.whereType<String>().toList(),
      _ => <String>[],
    };
    final changed = <Map<String, Object?>>[];
    for (final id in ids) {
      final current = _states[id];
      if (current == null || current['state'] == 'unavailable') continue;
      final attrs = Map<String, Object?>.of(
        current['attributes']! as Map<String, Object?>,
      );
      var state = current['state']! as String;

      switch ((domain, service)) {
        case ('light' || 'switch' || 'automation', 'turn_on'):
          state = 'on';
          if (domain == 'light') _applyLightData(attrs, data);
        case ('light' || 'switch' || 'automation', 'turn_off'):
          state = 'off';
          if (domain == 'light') attrs['brightness'] = null;
        case ('light' || 'switch' || 'automation', 'toggle'):
          state = state == 'on' ? 'off' : 'on';
        case ('climate', 'set_temperature'):
          final t = data['temperature'];
          if (t is num) attrs['temperature'] = t.toDouble();
        case ('climate', 'set_hvac_mode'):
          final mode = data['hvac_mode'];
          if (mode is String && (attrs['hvac_modes']! as List).contains(mode)) {
            state = mode;
          }
        case ('cover', 'open_cover'):
          state = 'open';
          attrs['current_position'] = 100;
        case ('cover', 'close_cover'):
          state = 'closed';
          attrs['current_position'] = 0;
        case ('cover', 'set_cover_position'):
          final p = data['position'];
          if (p is int) {
            attrs['current_position'] = p.clamp(0, 100);
            state = p == 0 ? 'closed' : 'open';
          }
        case ('lock', 'lock'):
          state = 'locked';
        case ('lock', 'unlock'):
          state = 'unlocked';
        case ('scene', 'turn_on'):
          state = _clock().toUtc().toIso8601String();
        default:
          continue;
      }
      changed.add(_setState(id, state, attrs));
    }
    return changed;
  }

  void _applyLightData(Map<String, Object?> attrs, Map<String, Object?> data) {
    final pct = data['brightness_pct'];
    final raw = data['brightness'];
    if (pct is num) {
      attrs['brightness'] = (pct.clamp(0, 100) * 255 / 100).round();
    } else if (raw is num) {
      attrs['brightness'] = raw.clamp(0, 255).round();
    } else {
      attrs['brightness'] ??= 255;
    }
    final kelvin = data['color_temp_kelvin'];
    if (kelvin is int) attrs['color_temp_kelvin'] = kelvin;
  }

  /// Changes a state and broadcasts `state_changed` (also used by tests).
  Map<String, Object?> _setState(
    String id,
    String state,
    Map<String, Object?> attrs,
  ) {
    final old = _states[id];
    final now = _clock().toUtc().toIso8601String();
    final next = {
      'entity_id': id,
      'state': state,
      'attributes': attrs,
      'last_changed': old?['state'] == state ? old!['last_changed'] : now,
      'last_updated': now,
    };
    _states[id] = next;
    final event = {
      'event_type': 'state_changed',
      'data': {'entity_id': id, 'old_state': old, 'new_state': next},
      'origin': 'LOCAL',
      'time_fired': now,
    };
    for (final socket in _sockets) {
      socket._dispatchEvent(event);
    }
    return next;
  }

  void setStateForTest(String id, String state) {
    final current = _states[id];
    if (current == null) return;
    _setState(
      id,
      state,
      Map.of(current['attributes']! as Map<String, Object?>),
    );
  }
}

class _MockSocket implements HaSocket {
  _MockSocket(this._server);

  final MockHomeAssistantServer _server;
  final StreamController<String> _out = StreamController<String>();
  final Map<int, String?> _subscriptions = {};
  bool _authenticated = false;

  @override
  Stream<String> get messages => _out.stream;

  void _emit(Map<String, Object?> message) {
    if (!_out.isClosed) _out.add(jsonEncode(message));
  }

  void _dispatchEvent(Map<String, Object?> event) {
    if (!_authenticated) return;
    _subscriptions.forEach((id, type) {
      if (type == null || type == event['event_type']) {
        _emit({'id': id, 'type': 'event', 'event': event});
      }
    });
  }

  @override
  void send(String message) {
    final msg = jsonDecode(message) as Map<String, Object?>;
    final id = msg['id'] as int?;
    final type = msg['type'];
    if (!_authenticated) {
      if (type != 'auth') return;
      if (_server.acceptsToken(msg['access_token'] as String?)) {
        _authenticated = true;
        _emit({
          'type': 'auth_ok',
          'ha_version': MockHomeAssistantServer.version,
        });
      } else {
        _emit({
          'type': 'auth_invalid',
          'message': 'Invalid access token or password',
        });
        unawaited(_serverClose());
      }
      return;
    }
    Map<String, Object?> ok([Object? result]) => {
      'id': id,
      'type': 'result',
      'success': true,
      'result': result,
    };

    switch (type) {
      case 'ping':
        _emit({'id': id, 'type': 'pong'});
      case 'subscribe_events':
        _subscriptions[id!] = msg['event_type'] as String?;
        _emit(ok());
      case 'unsubscribe_events':
        final known = _subscriptions.containsKey(msg['subscription']);
        _subscriptions.remove(msg['subscription']);
        _emit(
          known
              ? ok()
              : {
                  'id': id,
                  'type': 'result',
                  'success': false,
                  'error': {
                    'code': 'not_found',
                    'message': 'Subscription not found.',
                  },
                },
        );
      case 'get_states':
        // Snapshot is taken now; delivery may be delayed.
        final snapshot = _server.states;
        if (_server.getStatesDelay == Duration.zero) {
          _emit(ok(snapshot));
        } else {
          Future<void>.delayed(
            _server.getStatesDelay,
            () => _emit(ok(snapshot)),
          );
        }
      case 'config/area_registry/list':
        _emit(ok(_server.registries.areas));
      case 'config/device_registry/list':
        _emit(ok(_server.registries.devices));
      case 'config/entity_registry/list':
        _emit(ok(_server.registries.entities));
      case 'call_service':
        _server.callService(
          msg['domain']! as String,
          msg['service']! as String,
          {
            ...?msg['service_data'] as Map<String, Object?>?,
            ...?msg['target'] as Map<String, Object?>?,
          },
        );
        _emit(
          ok({
            'context': {'id': 'mock'},
          }),
        );
      default:
        _emit({
          'id': id,
          'type': 'result',
          'success': false,
          'error': {'code': 'unknown_command', 'message': 'Unknown command.'},
        });
    }
  }

  Future<void> _serverClose() async {
    _server._sockets.remove(this);
    await _out.close();
  }

  @override
  Future<void> close() => _serverClose();
}

/// [HomeAssistantApi] backed by [MockHomeAssistantServer].
class MockHomeAssistantApi implements HomeAssistantApi {
  MockHomeAssistantApi({
    required this.address,
    required this.server,
    required this._readToken,
  });

  @override
  final ServerAddress address;
  final MockHomeAssistantServer server;
  final Future<String?> Function() _readToken;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  Future<void> _requireAuth() async {
    await _latency();
    if (!server.online) {
      throw const AppFailure(
        FailureKind.network,
        debugMessage: 'mock server offline',
      );
    }
    if (!server.acceptsToken(await _readToken())) {
      throw const AppFailure(FailureKind.authentication, statusCode: 401);
    }
  }

  @override
  Future<ServerProbeResult> probe() async {
    await _latency();
    if (!server.online) {
      throw const AppFailure(
        FailureKind.network,
        debugMessage: 'mock server offline',
      );
    }
    return ServerProbeResult.reachableRequiresAuth;
  }

  @override
  Future<void> verifyAccessToken() => _requireAuth();

  @override
  Future<HaConfig> fetchConfig() async {
    await _requireAuth();
    return HaConfig.fromJson({
      'location_name': 'Demo dom (mock)',
      'version': MockHomeAssistantServer.version,
      'time_zone': 'Europe/Belgrade',
      'unit_system': {'temperature': '°C'},
      'components': ['light', 'switch', 'sensor', 'climate', 'scene'],
    });
  }

  @override
  Future<List<HaEntityState>> fetchStates() async {
    await _requireAuth();
    return parseStateList(server.states);
  }

  @override
  Future<List<HaEntityState>> callService(
    String domain,
    String service, {
    Map<String, Object?> data = const {},
  }) async {
    await _requireAuth();
    return parseStateList(server.callService(domain, service, data));
  }

  @override
  void close() {}
}
