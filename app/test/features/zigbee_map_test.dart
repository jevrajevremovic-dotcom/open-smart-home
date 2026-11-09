import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/features/devices/application/zigbee_map.dart';
import 'package:open_smart_home/features/devices/presentation/device_detail_screen.dart';

import '../widgets/app_widget_test.dart'
    show en, pumpApp, settle, tapKey, unmount;

void main() {
  test('ZHA devices with their neighbours', () {
    final net = parseZhaDevices([
      {
        'ieee': 'c',
        'name': 'Coordinator',
        'device_type': 'Coordinator',
        'neighbors': [
          {'ieee': 'r', 'lqi': '200'},
        ],
      },
      {
        'ieee': 'r',
        'name': 'Plug',
        'user_given_name': 'Hall plug',
        'device_type': 'Router',
        'device_reg_id': 'dev1',
        'neighbors': [
          {'ieee': 'c', 'lqi': 180},
          {'ieee': 'e', 'lqi': 40},
          {'ieee': 'ghost', 'lqi': 99},
        ],
      },
      {
        'ieee': 'e',
        'name': 'Motion',
        'device_type': 'EndDevice',
        'available': false,
        'neighbors': [
          {'ieee': 'r', 'lqi': 35},
          {'ieee': 'c', 'lqi': 20},
        ],
      },
      {'name': 'no ieee'},
    ]);
    expect(net.nodes.map((n) => n.name), [
      'Coordinator',
      'Hall plug',
      'Motion',
    ]);
    expect(net.node('r')!.haDeviceId, 'dev1');
    expect(net.node('e')!.available, isFalse);
    // One link per pair, the better reported LQI; unknown devices dropped.
    expect(net.links, hasLength(3));
    expect(
      net.links.firstWhere((l) => l.touches('c') && l.touches('r')).lqi,
      200,
    );
    expect(net.parentOf('e'), 'r');
    expect(net.weakLinks.map((l) => l.lqi), [20, 40]);

    final layout = layoutZigbee(net, const Size(400, 400));
    expect(layout['c'], const Offset(200, 200));
    expect((layout['e']! - layout['c']!).distance, closeTo(160, 0.01));
    expect((layout['r']! - layout['c']!).distance, closeTo(80, 0.01));
  });

  test('Zigbee2MQTT network map answer', () {
    final payload = jsonEncode({
      'status': 'ok',
      'data': {
        'type': 'raw',
        'routes': false,
        'value': {
          'nodes': [
            {
              'ieeeAddr': '0x1',
              'friendlyName': 'Coordinator',
              'type': 'Coordinator',
            },
            {'ieeeAddr': '0x2', 'friendlyName': 'Bulb', 'type': 'Router'},
            {
              'ieeeAddr': '0x3',
              'friendlyName': 'Door',
              'type': 'EndDevice',
              'failed': ['lqi'],
            },
          ],
          'links': [
            {
              'source': {'ieeeAddr': '0x2'},
              'target': {'ieeeAddr': '0x1'},
              'lqi': 150,
            },
            {
              'source': {'ieeeAddr': '0x3'},
              'target': {'ieeeAddr': '0x2'},
              'linkquality': 60,
            },
          ],
        },
      },
    });
    final net = parseZ2mNetworkMap(payload);
    expect(net.nodes.map((n) => n.role), [
      ZigbeeRole.coordinator,
      ZigbeeRole.router,
      ZigbeeRole.end,
    ]);
    expect(net.node('0x3')!.available, isFalse);
    expect(net.weakLinks.single.lqi, 60);
    expect(parseZ2mNetworkMap('{"status": "error"}').nodes, isEmpty);
  });

  testWidgets('More → Zigbee network: the weak link, its device', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(800, 1600));
    await settle(tester, 10);
    await tapKey(tester, 'openExtras');
    await settle(tester, 4);
    await tapKey(tester, 'extraZigbee');
    await settle(tester, 10);
    expect(find.byKey(const Key('zigbeeMap')), findsOneWidget);
    expect(find.text(en.zigbeeMapSummary(1, 3, 1)), findsOneWidget);
    final weak = find.byKey(
      const ValueKey(
        'zigbeeWeak-00:15:8d:00:05:06:07:08-00:12:4b:00:24:c0:00:02',
      ),
    );
    await tester.ensureVisible(weak);
    await tester.tap(weak);
    await settle(tester, 3);
    expect(find.byKey(const Key('zigbeeNode')), findsOneWidget);
    expect(find.text('↔ Utičnica hodnik: LQI 38'), findsOneWidget);
    await tester.ensureVisible(find.text(en.zigbeeOpenDevice));
    await tester.tap(find.text(en.zigbeeOpenDevice));
    await settle(tester, 6);
    expect(find.byType(DeviceDetailScreen), findsOneWidget);
    await unmount(tester);
  });
}
