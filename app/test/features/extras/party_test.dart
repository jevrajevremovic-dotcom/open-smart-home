import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/features/devices/application/device_providers.dart';
import 'package:open_smart_home/features/extras/party.dart';

import '../../widgets/app_widget_test.dart'
    show pumpApp, settle, tapKey, unmount;

void main() {
  testWidgets('party: colour lights dance, then go back as they were', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(800, 1600));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    final lights = partyLights(
      container.read(homeSnapshotProvider).devices.values,
    );
    expect(lights, isNotEmpty);
    final before = {for (final l in lights) l.id: l.state};

    await tapKey(tester, 'openExtras');
    await settle(tester, 5);
    await tapKey(tester, 'extraParty');
    await settle(tester, 2);
    await tapKey(tester, 'partyStart');
    await settle(tester, 2);
    expect(find.byKey(const Key('partyScreen')), findsOneWidget);
    await tester.pump(PartyRunner.step * 2);
    await settle(tester, 2);
    for (final l in lights) {
      final s = container.read(deviceProvider(l.id))!.state;
      expect(s.isOn, isTrue);
      expect(s.rgb, isNotNull);
    }

    await tapKey(tester, 'partyStop');
    await settle(tester, 4);
    expect(find.byKey(const Key('partyScreen')), findsNothing);
    for (final l in lights) {
      final s = container.read(deviceProvider(l.id))!.state;
      expect(s.isOn, before[l.id]!.isOn, reason: l.id);
      if (before[l.id]!.isOn == true) {
        expect(s.brightnessPercent, before[l.id]!.brightnessPercent);
      }
    }
    await unmount(tester);
  });
}
