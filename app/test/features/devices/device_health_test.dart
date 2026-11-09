import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/devices/application/device_health.dart';
import 'package:open_smart_home/features/devices/domain/device_kind.dart';
import 'package:open_smart_home/features/devices/domain/smart_home_device.dart';
import 'package:open_smart_home/integrations/home_assistant/models/ha_history.dart';

import '../../widgets/app_widget_test.dart'
    show en, goTo, pumpApp, settle, unmount;

SmartHomeDevice device({
  bool available = true,
  double? signal,
  String? unit,
  int? battery,
}) => SmartHomeDevice(
  id: 'switch.x',
  sourceId: 'switch.x',
  name: 'X',
  kind: DeviceKind.switchDevice,
  available: available,
  capabilities: const {},
  state: const DeviceState(raw: 'on'),
  protocol: DeviceProtocol.zigbee,
  metadata: DeviceMetadata(
    signalStrength: signal,
    signalUnit: unit,
    batteryPercent: battery,
  ),
);

void main() {
  final now = DateTime(2026, 11, 9, 12);
  HaHistoryPoint at(int hoursAgo, String state) =>
      HaHistoryPoint(now.subtract(Duration(hours: hoursAgo)), state);

  test('weak signal thresholds per unit', () {
    expect(weakSignal(-85, 'dBm'), isTrue);
    expect(weakSignal(-60, 'dBm'), isFalse);
    expect(weakSignal(38, 'lqi'), isTrue);
    expect(weakSignal(120, 'lqi'), isFalse);
    expect(weakSignal(20, '%'), isTrue);
    expect(weakSignal(20, null), isFalse, reason: 'unknown scale');
  });

  test('outages, downtime and the current outage come from history', () {
    final history = [
      at(100, 'on'),
      at(90, 'unavailable'),
      at(89, 'off'),
      at(50, 'unavailable'),
      at(48, 'on'),
      at(10, 'unavailable'),
    ];
    final h = diagnose(device(available: false), history, now);
    expect(h.outages, 3);
    expect(h.issues, [HealthIssue.offline, HealthIssue.flaky]);
    expect(h.offlineSince, now.subtract(const Duration(hours: 10)));
    expect(h.downtime, const Duration(hours: 13));
  });

  test('a healthy device; weak signal and low battery', () {
    expect(diagnose(device(), [at(5, 'on')], now).ok, isTrue);
    expect(
      diagnose(device(signal: 30, unit: 'lqi', battery: 10), [], now).issues,
      [HealthIssue.weakSignal, HealthIssue.lowBattery],
    );
  });

  testWidgets('devices not working: list and advice on the device', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(900, 1600));
    await settle(tester, 10);
    await goTo(tester, AppRoutes.device('binary_sensor.hallway_motion'));
    await settle(tester, 4);
    final issue = find.byKey(const ValueKey('healthIssue-weakSignal'));
    await tester.scrollUntilVisible(
      issue,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(issue, findsOneWidget);
    expect(find.text(en.healthAdviceWeakMesh), findsOneWidget);

    await goTo(tester, AppRoutes.device('switch.garage_heater'));
    await settle(tester, 4);
    final offline = find.byKey(const ValueKey('healthIssue-offline'));
    await tester.scrollUntilVisible(
      offline,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(offline, findsOneWidget);
    await unmount(tester);
  });
}
