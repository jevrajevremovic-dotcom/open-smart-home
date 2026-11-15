import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/core/errors/app_failure.dart';
import 'package:open_smart_home/core/network/server_address.dart';
import 'package:open_smart_home/features/authentication/data/server_profile.dart';
import 'package:open_smart_home/features/installer/homes_overview.dart';
import 'package:open_smart_home/integrations/home_assistant/api/dio_home_assistant_api.dart'
    show AccessTokenReader;
import 'package:open_smart_home/integrations/home_assistant/mock/mock_home_assistant.dart';
import 'package:open_smart_home/integrations/home_assistant/models/ha_models.dart';

import '../widgets/app_widget_test.dart'
    show en, goTo, pumpApp, settle, tapKey, unmount;

ServerAddress _address(String url) =>
    (ServerAddress.parse(url) as ValidServerAddress).address;

HaEntityState _s(String id, String state, [Map<String, Object?>? attrs]) =>
    HaEntityState(entityId: id, state: state, attributes: attrs ?? const {});

void main() {
  final profile = ServerProfile(
    address: _address('http://homeassistant.local:8123'),
  );

  test('counts what needs a look', () {
    final now = DateTime.now();
    final h = summarizeHome('Kuća A', profile, [
      _s('light.hall', 'unavailable', {'friendly_name': 'Hall'}),
      _s('button.restart', 'unavailable'),
      _s('sensor.door_battery', '9', {
        'device_class': 'battery',
        'friendly_name': 'Door',
      }),
      _s('sensor.lock_battery', '80', {'device_class': 'battery'}),
      _s('binary_sensor.remote_battery_low', 'on', {
        'device_class': 'battery',
        'friendly_name': 'Remote',
      }),
      _s('update.home_assistant_core_update', 'on', {
        'friendly_name': 'Home Assistant Core',
      }),
      _s(
        'sensor.backup_last_successful_automatic_backup',
        now.subtract(const Duration(days: 5)).toUtc().toIso8601String(),
      ),
    ], haVersion: '2026.11.1');
    expect(h.unavailable, ['Hall']);
    expect(h.lowBatteries, ['Door (9 %)', 'Remote']);
    expect(h.updates, ['Home Assistant Core']);
    expect(h.backupKnown, isTrue);
    expect(h.backupOld(now), isTrue);
    expect(h.level(now), HomeLevel.attention);

    final fine = summarizeHome('Kuća B', profile, [
      _s('light.hall', 'on'),
      _s(
        'sensor.backup_last_successful_automatic_backup',
        now.subtract(const Duration(hours: 5)).toIso8601String(),
      ),
    ]);
    expect(fine.level(now), HomeLevel.ok);
    expect(
      summarizeHome('Kuća C', profile, [_s('light.hall', 'on')]).level(now),
      HomeLevel.attention,
      reason: 'no backup information',
    );
  });

  test('away from the customer: through the remote address', () async {
    final server = MockHomeAssistantServer()
      ..unreachableHosts.add('homeassistant.local');
    final withRemote = profile.withRemoteAddress(
      _address('https://kuca-a.example.ts.net'),
    );
    MockHomeAssistantApi apiFor(ServerProfile p, AccessTokenReader read) =>
        MockHomeAssistantApi(
          address: p.address,
          server: server,
          readToken: read,
        );
    var h = await checkHome(
      'Kuća A',
      withRemote,
      apiFor: apiFor,
      token: () async => 'token',
    );
    expect(h.failure, isNull);
    expect(h.viaRemote, isTrue);
    expect(h.haVersion, isNotNull);
    expect(h.backupKnown, isTrue);

    server.online = false;
    h = await checkHome(
      'Kuća A',
      withRemote,
      apiFor: apiFor,
      token: () async => 'token',
    );
    expect(h.failure, FailureKind.network);
    expect(h.level(DateTime.now()), HomeLevel.down);

    server.online = true;
    h = await checkHome(
      'Kuća A',
      profile,
      apiFor: apiFor,
      token: () async => mockInvalidToken,
    );
    expect(h.failure, FailureKind.network, reason: 'no remote address');
    server.unreachableHosts.clear();
    h = await checkHome(
      'Kuća A',
      profile,
      apiFor: apiFor,
      token: () async => mockInvalidToken,
    );
    expect(h.failure, FailureKind.authentication);
  });

  testWidgets('Settings → All homes: the demo home and what needs a look', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(800, 1600));
    await settle(tester, 10);
    await goTo(tester, AppRoutes.settingsSection('server'));
    await tapKey(tester, 'homesOverview');
    await settle(tester, 10);
    // The demo's garage heater is unavailable; the backup is 20 h old.
    expect(find.text(en.homesOverviewSummary(1, 0, 1, 0)), findsOneWidget);
    expect(find.text(en.homeLevelAttention), findsOneWidget);
    expect(find.textContaining('Grejalica garaža'), findsOneWidget);
    expect(find.textContaining('Last automatic backup'), findsOneWidget);
    expect(find.text(en.homesActive), findsOneWidget);
    await unmount(tester);
  });
}
