import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/server_address.dart';
import '../api/home_assistant_api.dart';
import '../auth/ha_auth_client.dart';
import '../models/ha_calendar.dart';
import '../models/ha_config_flow.dart';
import '../models/ha_conversation.dart';
import '../models/ha_models.dart';
import '../websocket/ha_socket.dart';
import 'mock_camera_image.dart';
import 'mock_fixtures.dart';

/// Token that the mock server rejects, to exercise the auth-failure path.
const String mockInvalidToken = 'invalid';

/// An in-memory Home Assistant: entity states, a minimal service
/// implementation, and the WebSocket protocol. Both the mock REST API and
/// mock sockets talk to the same instance, so a service call made over REST
/// produces `state_changed` events on the WebSocket, as on a real server.
class MockHomeAssistantServer {
  /// [states] and [registries] replace the built-in demo home (used by
  /// performance tests with thousands of entities).
  MockHomeAssistantServer({
    DateTime Function()? clock,
    List<Map<String, Object?>>? states,
    ({
      List<Map<String, Object?>> areas,
      List<Map<String, Object?>> devices,
      List<Map<String, Object?>> entities,
    })?
    registries,
  }) : _clock = clock ?? DateTime.now,
       registries = registries ?? buildMockRegistries() {
    for (final s in states ?? buildMockStates(_clock())) {
      _states[s['entity_id']! as String] = s;
    }
  }

  static const String version = '2026.10.0-mock';

  final DateTime Function() _clock;
  final Map<String, Map<String, Object?>> _states = {};

  DateTime now() => _clock();

  /// Demo calendars (`GET /api/calendars`).
  List<Map<String, Object?>> calendars = [
    {'entity_id': 'calendar.porodica', 'name': 'Porodica'},
    {'entity_id': 'calendar.posao', 'name': 'Posao'},
  ];

  /// Demo events around "now", in the documented response format.
  List<Map<String, Object?>> calendarEvents(String calendarId) {
    final now = _clock();
    DateTime day(int offset) => DateTime(now.year, now.month, now.day + offset);
    Map<String, Object?> timed(String summary, int offset, int h1, int h2) => {
      'summary': summary,
      'start': {
        'dateTime': day(offset).add(Duration(hours: h1)).toIso8601String(),
      },
      'end': {
        'dateTime': day(offset).add(Duration(hours: h2)).toIso8601String(),
      },
    };
    Map<String, Object?> allDay(String summary, int offset, [int days = 1]) => {
      'summary': summary,
      'start': {'date': _date(day(offset))},
      'end': {'date': _date(day(offset + days))},
    };
    return switch (calendarId) {
      'calendar.porodica' => [
        timed('Vrtić', 0, 8, 16),
        allDay('Rođendan – Ana', 1),
        timed('Trening', 2, 18, 19),
        timed('Servis kotla', 3, 10, 11),
        allDay('Vikend kod bake', 9, 2),
        timed('Roditeljski sastanak', 16, 17, 18),
        timed('Zubar', 24, 9, 10),
        for (var w = 0; w < 6; w++) timed('Bazen', 7 * w + 5, 17, 18),
      ],
      'calendar.posao' => [
        timed('Sastanak tima', 0, 9, 11),
        timed('Prezentacija', 1, 13, 14),
        timed('Planiranje', 7, 10, 12),
        allDay('Konferencija', 14, 2),
      ],
      _ => const [],
    };
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// `GET /api/services` payload (only the parts the app looks at).
  List<Map<String, Object?>> get serviceList => [
    for (final (domain, services) in [
      ('light', ['turn_on', 'turn_off', 'toggle']),
      ('switch', ['turn_on', 'turn_off', 'toggle']),
      ('climate', ['set_temperature', 'set_hvac_mode', 'set_preset_mode']),
      if (zhaAvailable) ('zha', ['permit', 'remove']),
      ('mqtt', ['publish']),
    ])
      {
        'domain': domain,
        'services': {for (final s in services) s: <String, Object?>{}},
      },
  ];

  /// Whether the demo hub runs ZHA (tests switch it off).
  bool zhaAvailable = true;

  /// Last `mqtt.publish` call (topic, payload), for tests.
  (String, String)? lastMqttPublish;

  /// Remaining permit-join time as last requested (seconds; 0 = closed).
  int permitJoinSeconds = 0;
  final List<Timer> _pairingTimers = [];

  /// Devices that "join" while pairing is open, one after another.
  static const _joiningDevices = [
    (
      deviceId: 'd_new_door',
      name: 'Aqara senzor vrata',
      manufacturer: 'LUMI',
      model: 'MCCGQ11LM',
      ieee: '00:15:8d:00:0a:bc:de:01',
      entityId: 'binary_sensor.lumi_mccgq11lm_opening',
      state: 'off',
      attributes: {
        'friendly_name': 'Aqara senzor vrata',
        'device_class': 'door',
      },
    ),
    (
      deviceId: 'd_new_bulb',
      name: 'IKEA sijalica',
      manufacturer: 'IKEA of Sweden',
      model: 'TRADFRI bulb E27 WW 806lm',
      ieee: '00:0d:6f:ff:fe:12:34:56',
      entityId: 'light.ikea_tradfri_bulb',
      state: 'on',
      attributes: {
        'friendly_name': 'IKEA sijalica',
        'supported_color_modes': ['brightness'],
        'color_mode': 'brightness',
        'brightness': 200,
        'supported_features': 32,
      },
    ),
  ];

  void _permitJoin(int seconds) {
    permitJoinSeconds = seconds;
    for (final t in _pairingTimers) {
      t.cancel();
    }
    _pairingTimers.clear();
    if (seconds <= 0) return;
    for (final (i, d) in _joiningDevices.indexed) {
      if (_states.containsKey(d.entityId)) continue;
      _pairingTimers.add(Timer(Duration(seconds: 5 + i * 6), () => _join(d)));
    }
  }

  void _join(
    ({
      String deviceId,
      String name,
      String manufacturer,
      String model,
      String ieee,
      String entityId,
      String state,
      Map<String, Object?> attributes,
    })
    d,
  ) {
    if (permitJoinSeconds <= 0 || _states.containsKey(d.entityId)) return;
    registries.devices.add({
      'id': d.deviceId,
      'name': d.name,
      'name_by_user': null,
      'manufacturer': d.manufacturer,
      'model': d.model,
      'area_id': null,
      'identifiers': [
        ['zha', d.ieee],
      ],
      'connections': [
        ['zigbee', d.ieee],
      ],
      'via_device_id': null,
      'disabled_by': null,
    });
    registries.entities.add({
      'entity_id': d.entityId,
      'platform': 'zha',
      'device_id': d.deviceId,
      'area_id': null,
      'entity_category': null,
      'hidden_by': null,
      'disabled_by': null,
    });
    fireEvent('device_registry_updated', {
      'action': 'create',
      'device_id': d.deviceId,
    });
    fireEvent('entity_registry_updated', {
      'action': 'create',
      'entity_id': d.entityId,
    });
    _setState(d.entityId, d.state, Map.of(d.attributes));
  }

  /// `config/device_registry/update` (frontend API) for name and area.
  Map<String, Object?>? updateDevice(
    String deviceId, {
    Object? nameByUser,
    Object? areaId,
    bool setName = false,
    bool setArea = false,
  }) {
    final device = registries.devices
        .where((d) => d['id'] == deviceId)
        .firstOrNull;
    if (device == null) return null;
    if (setName) device['name_by_user'] = nameByUser;
    if (setArea) device['area_id'] = areaId;
    // Entities named after their device follow the new name.
    if (setName && nameByUser is String) {
      for (final e in registries.entities) {
        if (e['device_id'] != deviceId) continue;
        final id = e['entity_id']! as String;
        final s = _states[id];
        if (s == null) continue;
        _setState(id, s['state']! as String, {
          ...s['attributes']! as Map<String, Object?>,
          'friendly_name': nameByUser,
        });
      }
    }
    fireEvent('device_registry_updated', {
      'action': 'update',
      'device_id': deviceId,
    });
    return device;
  }

  // --- Config flows: devices HA "discovered" on the network ---

  /// flow_id → (handler, name, current step id).
  final Map<String, ({String handler, String name, String step})> _flows = {
    'flowshelly01': (
      handler: 'shelly',
      name: 'shellyplug-s-c8c9a3',
      step: 'confirm_discovery',
    ),
    'flowesphome01': (
      handler: 'esphome',
      name: 'kitchen-sensor',
      step: 'discovery_confirm',
    ),
  };

  /// `config_entries/flow/progress` payload.
  List<Map<String, Object?>> flowProgress() => [
    for (final MapEntry(:key, :value) in _flows.entries)
      {
        'flow_id': key,
        'handler': value.handler,
        'step_id': value.step,
        'context': {
          'source': 'zeroconf',
          'title_placeholders': {'name': value.name},
        },
      },
  ];

  Map<String, Object?> _flowStepJson(String flowId) {
    final f = _flows[flowId];
    if (f == null) {
      return {'type': 'abort', 'flow_id': flowId, 'reason': 'unknown_flow'};
    }
    Map<String, Object?> form(
      List<Map<String, Object?>> schema, {
      Map<String, String> errors = const {},
      Map<String, String> placeholders = const {},
    }) => {
      'type': 'form',
      'flow_id': flowId,
      'handler': f.handler,
      'step_id': f.step,
      'data_schema': schema,
      'errors': errors,
      'description_placeholders': placeholders,
    };
    return switch (f.step) {
      'confirm_discovery' => form(
        const [],
        placeholders: {'model': 'Shelly Plug S', 'host': '192.168.1.42'},
      ),
      'discovery_confirm' => form(const [], placeholders: {'name': f.name}),
      'encryption_key' => form(const [
        {'name': 'noise_psk', 'type': 'string', 'required': true},
      ]),
      _ => {'type': 'abort', 'flow_id': flowId, 'reason': 'unknown'},
    };
  }

  Map<String, Object?> flowStep(String flowId) => _flowStepJson(flowId);

  Map<String, Object?> flowSubmit(String flowId, Map<String, Object?> data) {
    final f = _flows[flowId];
    if (f == null) return _flowStepJson(flowId);
    switch ((f.handler, f.step)) {
      case ('shelly', 'confirm_discovery'):
        _flows.remove(flowId);
        _addWifiDevice(
          deviceId: 'd_shelly_plug',
          name: 'Shelly Plug S',
          manufacturer: 'Shelly',
          model: 'SHPLG-S',
          platform: 'shelly',
          identifier: ['shelly', 'c8c9a3'],
          entities: [
            (
              'switch.shelly_plug_s',
              'on',
              {'friendly_name': 'Shelly Plug S', 'device_class': 'outlet'},
            ),
          ],
        );
        return {
          'type': 'create_entry',
          'flow_id': flowId,
          'handler': 'shelly',
          'title': 'Shelly Plug S',
        };
      case ('esphome', 'discovery_confirm'):
        _flows[flowId] = (
          handler: f.handler,
          name: f.name,
          step: 'encryption_key',
        );
        return _flowStepJson(flowId);
      case ('esphome', 'encryption_key'):
        final key = data['noise_psk'];
        if (key is! String || key.length < 8) {
          return {
            ..._flowStepJson(flowId),
            'errors': {'base': 'invalid_psk'},
          };
        }
        _flows.remove(flowId);
        _addWifiDevice(
          deviceId: 'd_kitchen_sensor',
          name: 'kitchen-sensor',
          manufacturer: 'Espressif',
          model: 'ESP32',
          platform: 'esphome',
          identifier: ['esphome', 'kitchen-sensor'],
          entities: [
            (
              'sensor.kitchen_sensor_temperature',
              '23.1',
              {
                'friendly_name': 'Kuhinja temperatura',
                'device_class': 'temperature',
                'unit_of_measurement': '°C',
                'state_class': 'measurement',
              },
            ),
          ],
        );
        return {
          'type': 'create_entry',
          'flow_id': flowId,
          'handler': 'esphome',
          'title': 'kitchen-sensor',
        };
    }
    return _flowStepJson(flowId);
  }

  void flowAbort(String flowId) => _flows.remove(flowId);

  /// A few `frontend/get_translations` keys (category `config`).
  Map<String, String> flowTranslations(Object? language) {
    final sr = language is String && language.startsWith('sr');
    return {
      'component.shelly.config.step.confirm_discovery.description': sr
          ? 'Da li želite da podesite {model} na adresi {host}?'
          : 'Do you want to set up the {model} at {host}?',
      'component.esphome.config.step.discovery_confirm.description': sr
          ? 'Da li želite da dodate ESPHome uređaj `{name}` u Home Assistant?'
          : 'Do you want to add the ESPHome node `{name}` to Home Assistant?',
      'component.esphome.config.step.encryption_key.title': sr
          ? 'Ključ za šifrovanje'
          : 'Enter encryption key',
      'component.esphome.config.step.encryption_key.data.noise_psk': sr
          ? 'Ključ za šifrovanje'
          : 'Encryption key',
      'component.esphome.config.error.invalid_psk': sr
          ? 'Ključ nije ispravan.'
          : 'The transport encryption key is invalid.',
    };
  }

  void _addWifiDevice({
    required String deviceId,
    required String name,
    required String manufacturer,
    required String model,
    required String platform,
    required List<String> identifier,
    required List<(String, String, Map<String, Object?>)> entities,
  }) {
    registries.devices.add({
      'id': deviceId,
      'name': name,
      'name_by_user': null,
      'manufacturer': manufacturer,
      'model': model,
      'area_id': null,
      'identifiers': [identifier],
      'connections': <List<String>>[],
      'via_device_id': null,
      'disabled_by': null,
    });
    for (final (id, _, _) in entities) {
      registries.entities.add({
        'entity_id': id,
        'platform': platform,
        'device_id': deviceId,
        'area_id': null,
        'entity_category': null,
        'hidden_by': null,
        'disabled_by': null,
      });
    }
    fireEvent('device_registry_updated', {
      'action': 'create',
      'device_id': deviceId,
    });
    for (final (id, state, attrs) in entities) {
      _setState(id, state, Map.of(attrs));
    }
  }

  /// Camera snapshots served so far (lets tests check polling stops).
  int cameraRequests = 0;
  final Set<_MockSocket> _sockets = {};

  final ({
    List<Map<String, Object?>> areas,
    List<Map<String, Object?>> devices,
    List<Map<String, Object?>> entities,
  })
  registries;

  /// `energy/get_prefs` payload; `null` simulates "Energy not configured".
  Map<String, Object?>? energyPrefs = buildMockEnergyPrefs();

  /// `recorder/statistics_during_period` with `types: [change]`, generated
  /// from [mockHourlyEnergy]. Only past buckets are returned.
  Map<String, Object?> statistics({
    required DateTime start,
    required DateTime end,
    required List<String> ids,
    required String period,
  }) {
    final now = _clock();
    final result = <String, Object?>{};
    for (final id in ids) {
      final rows = <Map<String, Object?>>[];
      var t = start.toLocal();
      while (t.isBefore(end) && t.isBefore(now)) {
        final next = period == 'hour'
            ? t.add(const Duration(hours: 1))
            : DateTime(t.year, t.month, t.day + 1);
        var change = 0.0;
        for (
          var h = t;
          h.isBefore(next) && h.isBefore(now);
          h = h.add(const Duration(hours: 1))
        ) {
          change += mockHourlyEnergy(id, h);
        }
        rows.add({
          'start': t.millisecondsSinceEpoch,
          'end': next.millisecondsSinceEpoch,
          'change': double.parse(change.toStringAsFixed(3)),
        });
        t = next;
      }
      if (rows.isNotEmpty) result[id] = rows;
    }
    return result;
  }

  /// Synthetic 24 hours from the current hour (type hourly): a daily
  /// temperature curve with a rain shower in the afternoon.
  List<Map<String, Object?>> hourlyForecast() {
    final now = _clock();
    final start = DateTime(now.year, now.month, now.day, now.hour);
    return [
      for (var i = 0; i < 24; i++)
        () {
          final t = start.add(Duration(hours: i));
          final h = t.hour;
          final rain = h >= 15 && h <= 17;
          return {
            'datetime': t.toUtc().toIso8601String(),
            'condition': rain
                ? 'rainy'
                : h >= 21 || h < 6
                ? 'clear-night'
                : h < 10
                ? 'partlycloudy'
                : 'sunny',
            // Coolest around 05:00, warmest around 15:00.
            'temperature': (13.0 + 5 * math.cos((h - 15) / 24 * 2 * math.pi))
                .roundToDouble(),
            'precipitation_probability': rain ? 60.0 : 5.0,
          };
        }(),
    ];
  }

  /// Synthetic 7-day forecast (mock `weather.get_forecasts`, type daily).
  List<Map<String, Object?>> dailyForecast() {
    const conditions = [
      'partlycloudy',
      'sunny',
      'rainy',
      'cloudy',
      'sunny',
      'lightning-rainy',
      'partlycloudy',
    ];
    final today = _clock();
    return [
      for (var i = 0; i < 7; i++)
        {
          'datetime': DateTime(
            today.year,
            today.month,
            today.day + i,
            12,
          ).toUtc().toIso8601String(),
          'condition': conditions[i],
          'temperature': 18.0 + i - (i == 2 ? 4 : 0),
          'templow': 9.0 + i / 2,
          'precipitation': i == 2 ? 6.4 : 0.0,
        },
    ];
  }

  /// `GET /api/config` / WS `get_config` payload.
  final Map<String, Object?> config = {
    'location_name': 'Demo dom (mock)',
    'version': version,
    'time_zone': 'Europe/Belgrade',
    'latitude': 44.8125,
    'longitude': 20.4612,
    'unit_system': {'temperature': '°C'},
    'components': ['light', 'switch', 'sensor', 'climate', 'scene'],
  };

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

  // --- OAuth2 (see MockHaAuthClient) ---
  // Codes and refresh tokens are recognised by their format, so they stay
  // valid across a page reload (which recreates this in-memory server in
  // the web build). Only used codes and revoked tokens are remembered.
  int _nextAuthCode = 1;
  final Set<String> _usedAuthCodes = {};

  /// Refresh tokens revoked via `/auth/revoke`.
  final Set<String> revokedRefreshTokens = {};
  Duration accessTokenLifetime = const Duration(minutes: 30);

  /// Number of refresh-token grants (tests check single-flight refresh).
  int refreshCount = 0;

  /// Currently open WebSocket connections (leak checks in tests).
  int get openConnections => _sockets.length;

  /// Event subscriptions held by open connections (leak checks in tests).
  int get activeSubscriptions =>
      _sockets.fold(0, (sum, s) => sum + s._subscriptions.length);

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
    if (domain == 'zha' && service == 'permit' && zhaAvailable) {
      final d = data['duration'];
      _permitJoin(d is num ? d.toInt() : 60);
      return const [];
    }
    if (domain == 'mqtt' && service == 'publish') {
      final topic = data['topic'];
      final payload = data['payload'];
      if (topic is String) {
        lastMqttPublish = (topic, payload is String ? payload : '');
      }
      return const [];
    }
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
        case ('media_player', 'media_play_pause'):
          state = state == 'playing' ? 'paused' : 'playing';
        case ('media_player', 'media_next_track' || 'media_previous_track'):
          const titles = ['Kafa i kiša', 'Tiho jutro', 'Večernji šetač'];
          final i = titles.indexOf(attrs['media_title'] as String? ?? '');
          final step = service == 'media_next_track' ? 1 : titles.length - 1;
          attrs['media_title'] = titles[(i + step) % titles.length];
          state = 'playing';
        case ('media_player', 'volume_set'):
          final v = data['volume_level'];
          if (v is num) attrs['volume_level'] = v.toDouble();
        case ('media_player', 'select_source'):
          final source = data['source'];
          if (source is String &&
              (attrs['source_list'] as List?)?.contains(source) == true) {
            attrs['source'] = source;
          }
        case ('media_player', 'turn_off'):
          state = 'off';
        case ('media_player', 'turn_on'):
          state = 'idle';
        case ('climate', 'turn_off'):
          attrs['last_on_mode'] = state;
          state = 'off';
        case ('climate', 'turn_on'):
          if (state == 'off') {
            state = attrs.remove('last_on_mode') as String? ?? 'heat';
          }
        case ('climate', 'set_preset_mode'):
          final mode = data['preset_mode'];
          if (mode is String &&
              (attrs['preset_modes']! as List).contains(mode)) {
            attrs['preset_mode'] = mode;
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
    final rgb = data['rgb_color'];
    if (rgb is List && rgb.length == 3) {
      attrs['rgb_color'] = List<Object?>.of(rgb);
      attrs['color_mode'] = 'rgb';
    }
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
      case 'get_config':
        _emit(ok(_server.config));
      case 'energy/get_prefs':
        final prefs = _server.energyPrefs;
        _emit(
          prefs == null
              ? {
                  'id': id,
                  'type': 'result',
                  'success': false,
                  'error': {'code': 'not_found', 'message': 'No prefs'},
                }
              : ok(prefs),
        );
      case 'recorder/statistics_during_period':
        _emit(
          ok(
            _server.statistics(
              start: DateTime.parse(msg['start_time']! as String),
              end: DateTime.parse(msg['end_time']! as String),
              ids: (msg['statistic_ids']! as List).cast<String>(),
              period: msg['period']! as String,
            ),
          ),
        );
      case 'config/area_registry/list':
        _emit(ok(_server.registries.areas));
      case 'config/device_registry/list':
        _emit(ok(_server.registries.devices));
      case 'config_entries/flow/progress':
        _emit(ok(_server.flowProgress()));
      case 'frontend/get_translations':
        _emit(ok({'resources': _server.flowTranslations(msg['language'])}));
      case 'config/device_registry/update':
        final device = _server.updateDevice(
          msg['device_id'] as String? ?? '',
          nameByUser: msg['name_by_user'],
          areaId: msg['area_id'],
          setName: msg.containsKey('name_by_user'),
          setArea: msg.containsKey('area_id'),
        );
        if (device == null) {
          _emit({
            'id': id,
            'type': 'result',
            'success': false,
            'error': {'code': 'not_found', 'message': 'Device not found'},
          });
        } else {
          _emit(ok(device));
        }
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
    return HaConfig.fromJson(server.config);
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
  Future<Object?> callServiceForResponse(
    String domain,
    String service, {
    Map<String, Object?> data = const {},
  }) async {
    await _requireAuth();
    if (domain != 'weather' || service != 'get_forecasts') {
      throw AppFailure(
        FailureKind.validation,
        debugMessage: '$domain.$service returns no response',
      );
    }
    final id = data['entity_id'];
    final hourly = data['type'] == 'hourly';
    // Shape of the documented `weather.get_forecasts` response.
    return {
      if (id is String)
        id: {
          'forecast': hourly ? server.hourlyForecast() : server.dailyForecast(),
        },
    };
  }

  @override
  Future<Map<String, Set<String>>> fetchServices() async {
    await _requireAuth();
    return parseServiceList(server.serviceList);
  }

  @override
  Future<List<HaCalendar>> fetchCalendars() async {
    await _requireAuth();
    await _latency();
    return HaCalendar.parseList(server.calendars);
  }

  @override
  Future<List<HaCalendarEvent>> fetchCalendarEvents(
    String calendarId,
    DateTime start,
    DateTime end,
  ) async {
    await _requireAuth();
    await _latency();
    return [
      for (final e in HaCalendarEvent.parseList(
        server.calendarEvents(calendarId),
        calendarId,
      ))
        if (e.start.isBefore(end) && e.end.isAfter(start)) e,
    ];
  }

  @override
  Future<HaFlowStep> configFlowStep(String flowId) async {
    await _requireAuth();
    await _latency();
    return HaFlowStep.parse(server.flowStep(flowId));
  }

  @override
  Future<HaFlowStep> configFlowSubmit(
    String flowId,
    Map<String, Object?> data,
  ) async {
    await _requireAuth();
    await _latency();
    return HaFlowStep.parse(server.flowSubmit(flowId, data));
  }

  @override
  Future<void> configFlowAbort(String flowId) async {
    await _requireAuth();
    server.flowAbort(flowId);
  }

  @override
  Future<HaConversationReply> processConversation(
    String text, {
    String? language,
    String? conversationId,
  }) async {
    await _requireAuth();
    await _latency();
    final t = text.toLowerCase();
    final sr = language?.startsWith('sr') ?? false;
    bool has(List<String> words) => words.any(t.contains);
    Map<String, Object?> reply(String speech, String type) => {
      'conversation_id': conversationId ?? 'mock-conversation',
      'response': {
        'response_type': type,
        'speech': {
          'plain': {'speech': speech},
        },
      },
    };
    final lights = [
      for (final s in server.states)
        if ((s['entity_id']! as String).startsWith('light.'))
          s['entity_id']! as String,
    ];
    if (has(['svetl', 'light'])) {
      final off = has(['ugasi', 'isključi', 'iskljuci', 'turn off', 'off']);
      final on = has(['upali', 'uključi', 'ukljuci', 'turn on', ' on']);
      if (off || on) {
        await callService(
          'light',
          off ? 'turn_off' : 'turn_on',
          data: {'entity_id': lights},
        );
        return HaConversationReply.parse(
          reply(
            sr
                ? (off ? 'Ugasio sam svetla.' : 'Upalio sam svetla.')
                : (off ? 'Turned off the lights.' : 'Turned on the lights.'),
            'action_done',
          ),
        );
      }
    }
    if (has(['temperatur'])) {
      return HaConversationReply.parse(
        reply(
          sr ? 'U dnevnoj sobi je 22,4 °C.' : 'The living room is 22.4 °C.',
          'query_answer',
        ),
      );
    }
    return HaConversationReply.parse(
      reply(
        sr ? 'Izvinite, nisam razumeo.' : "Sorry, I couldn't understand that.",
        'error',
      ),
    );
  }

  @override
  Future<Uint8List> fetchImage(String path) async {
    await _requireAuth();
    const proxy = '/api/camera_proxy/';
    if (path.startsWith(proxy)) {
      final id = Uri.decodeComponent(path.substring(proxy.length));
      final cameras = [
        for (final s in server.states)
          if ((s['entity_id']! as String).startsWith('camera.'))
            s['entity_id']! as String,
      ];
      final index = cameras.indexOf(id);
      if (index >= 0) {
        server.cameraRequests++;
        await _latency();
        return mockCameraFrame(index, server.now());
      }
    }
    // Demo people have no pictures; the UI shows their initials.
    throw const AppFailure(FailureKind.server, debugMessage: 'no image');
  }

  @override
  void close() {}
}

/// [HaAuthClient] for mock mode: "logging in" redirects straight back with
/// a code, so the whole OAuth2 flow can be exercised without a server.
class MockHaAuthClient implements HaAuthClient {
  MockHaAuthClient(this.server);

  final MockHomeAssistantServer server;

  @override
  Uri authorizeUrl({
    required String clientId,
    required Uri redirectUri,
    required String state,
  }) {
    final code =
        'mock-code-${DateTime.now().microsecondsSinceEpoch}-${server._nextAuthCode++}';
    return redirectUri.replace(queryParameters: {'code': code, 'state': state});
  }

  @override
  Future<OAuthTokenResponse> exchangeCode({
    required String code,
    required String clientId,
  }) async {
    if (!code.startsWith('mock-code-') || !server._usedAuthCodes.add(code)) {
      throw const AppFailure(
        FailureKind.authentication,
        statusCode: 400,
        debugMessage: 'invalid_grant',
      );
    }
    final refresh =
        'mock-refresh-${DateTime.now().microsecondsSinceEpoch}-${server._nextAuthCode++}';
    return OAuthTokenResponse(
      accessToken: 'mock-access-${server._nextAuthCode++}',
      expiresIn: server.accessTokenLifetime,
      refreshToken: refresh,
    );
  }

  @override
  Future<OAuthTokenResponse> refresh({
    required String refreshToken,
    required String clientId,
  }) async {
    server.refreshCount++;
    if (!refreshToken.startsWith('mock-refresh-') ||
        server.revokedRefreshTokens.contains(refreshToken)) {
      throw const AppFailure(
        FailureKind.authentication,
        statusCode: 400,
        debugMessage: 'invalid_grant',
      );
    }
    return OAuthTokenResponse(
      accessToken: 'mock-access-${server._nextAuthCode++}',
      expiresIn: server.accessTokenLifetime,
    );
  }

  @override
  Future<void> revoke(String refreshToken) async =>
      server.revokedRefreshTokens.add(refreshToken);
}
