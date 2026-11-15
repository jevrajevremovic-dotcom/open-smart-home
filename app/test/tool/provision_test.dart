import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/provision_lib.dart';

const _token = 'secret-test-token-123';

Map<String, Object?> _state(
  String id,
  String state, [
  Map<String, Object?>? a,
]) => {'entity_id': id, 'state': state, 'attributes': a ?? <String, Object?>{}};

ProvisionData _data({Map<String, Object?>? backup, String? external}) =>
    ProvisionData(
      config: {
        'version': '2026.11.1',
        'location_name': 'Kuća Petrović',
        'time_zone': 'Europe/Belgrade',
        'country': 'RS',
        'currency': 'RSD',
        'external_url': ?external,
      },
      states: [
        _state('light.hall', 'unavailable', {'friendly_name': 'Hodnik'}),
        _state('button.x', 'unavailable'),
        _state('sensor.door_battery', '9', {
          'device_class': 'battery',
          'friendly_name': 'Vrata',
        }),
        _state('update.core', 'on', {'friendly_name': 'Home Assistant Core'}),
      ],
      areas: [
        {'area_id': 'kitchen', 'name': 'Kuhinja'},
      ],
      devices: [
        {'id': 'd1', 'name': 'Utičnica', 'area_id': 'kitchen'},
        {'id': 'd2', 'name': 'Senzor', 'area_id': null},
        {'id': 'd3', 'name': 'Sun', 'area_id': null, 'entry_type': 'service'},
      ],
      entities: [
        {'entity_id': 'light.hall'},
      ],
      entries: [
        {'domain': 'zha', 'title': 'ZHA', 'state': 'loaded'},
        {'domain': 'mqtt', 'title': 'MQTT', 'state': 'setup_retry'},
      ],
      backup: backup,
    );

void main() {
  test('what to create and change', () {
    expect(
      missingAreas(
        [
          {'name': 'Kuhinja'},
        ],
        ['kuhinja', ' Garaža ', ''],
      ),
      ['Garaža'],
    );
    expect(
      coreChanges(
        {'time_zone': 'UTC', 'country': 'RS'},
        timeZone: 'Europe/Belgrade',
        country: 'RS',
      ),
      {'time_zone': 'Europe/Belgrade'},
    );
    expect(backupSchedule(null), isNull);
    expect(
      backupSchedule({
        'config': {
          'schedule': {'recurrence': 'daily'},
        },
      }),
      'daily',
    );
    expect(
      backupSchedule({
        'config': {
          'schedule': {'recurrence': 'never'},
        },
      }),
      isNull,
    );
  });

  test('checks and the handover report', () {
    final checks = handoverChecks(_data());
    final bad = [
      for (final c in checks)
        if (!c.ok) c.text,
    ];
    expect(bad, hasLength(7));
    expect(bad.join('\n'), contains('Hodnik'));
    expect(bad.join('\n'), isNot(contains('button.x')));
    expect(bad.join('\n'), contains('Vrata (9 %)'));
    expect(bad.join('\n'), contains('Senzor'));
    expect(bad.join('\n'), isNot(contains('Sun')), reason: 'a service');
    expect(bad.join('\n'), contains('MQTT (mqtt: setup_retry)'));

    final good = handoverChecks(
      _data(
        external: 'https://kuca.example.ts.net',
        backup: {
          'config': {
            'schedule': {'recurrence': 'daily'},
            'last_completed_automatic_backup': '2026-11-15T03:00:00+01:00',
          },
        },
      ),
    );
    expect(good.where((c) => c.ok), hasLength(2));

    final report = handoverReport(
      _data(),
      DateTime(2026, 11, 15, 18, 5),
      host: '192.168.1.10',
    );
    expect(report, startsWith('# Zapisnik o primopredaji – Kuća Petrović'));
    expect(report, contains('| Datum | 15.11.2026. 18:05 |'));
    expect(report, contains('- Kuhinja: 1 uređaja'));
    expect(report, contains('- (bez prostorije): 1 uređaja'));
    expect(report, contains('- zha'));
    expect(report, contains('- [ ] Zidni panel'));
  });

  test(
    'the tool against a Home Assistant: reads, applies, writes the report',
    () async {
      final received = <Map<String, Object?>>[];
      final areas = [
        {'area_id': 'kitchen', 'name': 'Kuhinja'},
      ];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        if (request.uri.path != '/api/websocket') {
          request.response.statusCode = 404;
          await request.response.close();
          return;
        }
        // Closed when the tool hangs up (the loop below ends).
      // ignore: close_sinks
      final ws = await WebSocketTransformer.upgrade(request);
        ws.add(jsonEncode({'type': 'auth_required'}));
        await for (final raw in ws) {
          final msg = (jsonDecode(raw as String) as Map)
              .cast<String, Object?>();
          if (msg['type'] == 'auth') {
            ws.add(
              jsonEncode({
                'type': msg['access_token'] == _token
                    ? 'auth_ok'
                    : 'auth_invalid',
              }),
            );
            continue;
          }
          received.add(msg);
          Object? result;
          switch (msg['type']) {
            case 'get_config':
              result = {
                'version': '2026.11.1',
                'location_name': 'Probna kuća',
                'time_zone': 'UTC',
                'country': 'RS',
              };
            case 'config/area_registry/list':
              result = areas;
            case 'config/area_registry/create':
              areas.add({'area_id': 'new', 'name': '${msg['name']}'});
              result = areas.last;
            case 'backup/config/info':
              ws.add(
                jsonEncode({
                  'id': msg['id'],
                  'type': 'result',
                  'success': false,
                  'error': {'code': 'unknown_command', 'message': 'Unknown'},
                }),
              );
              continue;
            default:
              result = <Object?>[];
          }
          ws.add(
            jsonEncode({
              'id': msg['id'],
              'type': 'result',
              'success': true,
              'result': result,
            }),
          );
        }
      });
      final dir = await Directory.systemTemp.createTemp('provision');
      addTearDown(() async {
        await server.close(force: true);
        await dir.delete(recursive: true);
      });
      final flutterRoot = Platform.environment['FLUTTER_ROOT'];
      final dart = flutterRoot == null ? 'dart' : '$flutterRoot/bin/dart';
      final report = '${dir.path}/zapisnik.md';
      final run = await Process.run(
        dart,
        [
          'run',
          'tool/provision.dart',
          'http://127.0.0.1:${server.port}',
          '--areas',
          'Kuhinja,Garaža',
          '--time-zone',
          'Europe/Belgrade',
          '--apply',
          '--report',
          report,
        ],
        environment: {'HA_TOKEN': _token},
      );
      expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
      expect(
        received.where((m) => m['type'] == 'config/area_registry/create'),
        hasLength(1),
        reason: 'Kuhinja exists already',
      );
      expect(
        received.singleWhere(
          (m) => m['type'] == 'config/area_registry/create',
        )['name'],
        'Garaža',
      );
      expect(
        received.singleWhere(
          (m) => m['type'] == 'config/core/update',
        )['time_zone'],
        'Europe/Belgrade',
      );
      final text = await File(report).readAsString();
      expect(text, contains('# Zapisnik o primopredaji – Probna kuća'));
      expect(text, contains('Garaža'));
      expect('${run.stdout}$text', isNot(contains(_token)));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
