import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/core/errors/app_failure.dart';
import 'package:open_smart_home/core/network/local_network.dart';
import 'package:open_smart_home/core/network/server_address.dart';
import 'package:open_smart_home/features/authentication/data/server_profile.dart';
import 'package:open_smart_home/features/connection/application/connection_check.dart';
import 'package:open_smart_home/integrations/home_assistant/mock/mock_home_assistant.dart';

import '../widgets/app_widget_test.dart' show en, pumpApp, settle, unmount;

class _FakeNetwork implements LocalNetwork {
  bool? online = true;
  final woken = <List<int>>[];

  @override
  Future<bool?> hasNetwork() async => online;

  @override
  bool get canWake => true;

  @override
  Future<void> wake(List<int> mac) async => woken.add(mac);
}

ServerAddress _address(String url) =>
    (ServerAddress.parse(url) as ValidServerAddress).address;

void main() {
  test('MAC addresses and the magic packet', () {
    expect(parseMac('aa:BB:cc:dd:ee:01'), [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 1]);
    expect(parseMac('AA-BB-CC-DD-EE-01'), isNotNull);
    expect(parseMac('aabbccddee01'), isNotNull);
    expect(parseMac('AA:BB:CC'), isNull);
    expect(parseMac('GG:BB:CC:DD:EE:01'), isNull);
    final packet = magicPacket([1, 2, 3, 4, 5, 6]);
    expect(packet.length, 102);
    expect(packet.take(6), everyElement(0xFF));
    expect(packet.sublist(96), [1, 2, 3, 4, 5, 6]);
  });

  Future<Map<CheckStep, CheckLine>> run(
    MockHomeAssistantServer server, {
    String token = 'token',
    bool? online = true,
    bool remote = true,
  }) async {
    var profile = ServerProfile(
      address: _address('http://homeassistant.local:8123'),
    );
    if (remote) {
      profile = profile.withRemoteAddress(
        _address('https://ha.example.ts.net'),
      );
    }
    final lines = await runConnectionCheck(
      profile: profile,
      apiFor: (p, read) => MockHomeAssistantApi(
        address: p.address,
        server: server,
        readToken: read,
      ),
      token: () async => token,
      network: _FakeNetwork()..online = online,
    );
    return {for (final l in lines) l.step: l};
  }

  test('each step and what it found', () async {
    final server = MockHomeAssistantServer();
    var r = await run(server);
    expect(r.values.map((l) => l.outcome), everyElement(CheckOutcome.ok));

    // Away from home: the home address is silent, the remote one works.
    server.unreachableHosts.add('homeassistant.local');
    r = await run(server);
    expect(r[CheckStep.home]!.outcome, CheckOutcome.failed);
    expect(r[CheckStep.home]!.failure, FailureKind.network);
    expect(r[CheckStep.remote]!.outcome, CheckOutcome.ok);
    expect(r[CheckStep.signIn]!.outcome, CheckOutcome.ok);

    // Server off, no remote address, no network on the phone.
    server.online = false;
    r = await run(server, online: false, remote: false);
    expect(r[CheckStep.network]!.outcome, CheckOutcome.failed);
    expect(r[CheckStep.remote]!.outcome, CheckOutcome.skipped);
    expect(r[CheckStep.signIn]!.outcome, CheckOutcome.skipped);

    // Back, but the token was removed in HA.
    server
      ..online = true
      ..unreachableHosts.clear();
    r = await run(server, token: mockInvalidToken);
    expect(r[CheckStep.signIn]!.outcome, CheckOutcome.failed);
    expect(r[CheckStep.signIn]!.failure, FailureKind.authentication);
  });

  testWidgets('from the dashboard: the server is down, wake it', (
    tester,
  ) async {
    final server = MockHomeAssistantServer()..online = false;
    final network = _FakeNetwork();
    await pumpApp(
      tester,
      signedIn: true,
      server: server,
      size: const Size(800, 1400),
      overrides: [localNetworkProvider.overrideWithValue(network)],
    );
    await settle(tester, 10);
    await tester.tap(find.byKey(const Key('connectionCheck')));
    await settle(tester, 10);
    expect(find.text(en.checkHomeFix), findsOneWidget);
    expect(find.text(en.wolHintDown), findsOneWidget);

    await tester.enterText(find.byKey(const Key('wolMac')), 'nonsense');
    await tester.tap(find.byKey(const Key('wolWake')));
    await settle(tester, 2);
    expect(network.woken, isEmpty);
    await tester.enterText(
      find.byKey(const Key('wolMac')),
      'AA:BB:CC:DD:EE:01',
    );
    await tester.tap(find.byKey(const Key('wolWake')));
    await settle(tester, 8);
    expect(network.woken.single, [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 1]);
    expect(find.text(en.wolSent), findsOneWidget);
    await unmount(tester);
  });
}
