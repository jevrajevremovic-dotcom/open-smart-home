import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/automations/domain/habits.dart';
import 'package:open_smart_home/features/automations/domain/simple_automation.dart';
import 'package:open_smart_home/features/devices/domain/device_kind.dart';
import 'package:open_smart_home/features/devices/domain/smart_home_device.dart';
import 'package:open_smart_home/integrations/home_assistant/home_assistant_providers.dart';
import 'package:open_smart_home/integrations/home_assistant/models/ha_history.dart';

import '../widgets/app_widget_test.dart'
    show goTo, pumpApp, settle, tapKey, unmount;

SmartHomeDevice _device(String id, DeviceKind kind, [String? deviceClass]) =>
    SmartHomeDevice(
      id: id,
      sourceId: id,
      name: id,
      kind: kind,
      available: true,
      capabilities: const {},
      state: const DeviceState(raw: 'off'),
      metadata: DeviceMetadata(haDeviceClass: deviceClass),
    );

HaLogbookEntry _e(
  DateTime t,
  String id,
  String state, {
  bool user = true,
  bool automated = false,
}) => HaLogbookEntry(
  when: t,
  entityId: id,
  state: state,
  byUser: user,
  automated: automated,
);

void main() {
  final devices = {
    'light.lamp': _device('light.lamp', DeviceKind.light),
    'light.hall': _device('light.hall', DeviceKind.light),
    'lock.door': _device('lock.door', DeviceKind.lock),
    'binary_sensor.door': _device(
      'binary_sensor.door',
      DeviceKind.contactSensor,
      'door',
    ),
  };
  // Monday 2 November 2026 and the 13 days after it.
  final days = [for (var i = 0; i < 14; i++) DateTime(2026, 11, 2 + i)];

  test('a light switched off around the same time most days', () {
    final entries = [
      for (final (i, d) in days.indexed)
        if (i != 3) // one evening out
          _e(
            d.add(Duration(hours: 23, minutes: 50 + (i % 3) * 10)),
            'light.lamp',
            'off',
          ),
      // Noise: other times, and the same change made by an automation.
      _e(days[1].add(const Duration(hours: 9)), 'light.lamp', 'off'),
      for (final d in days)
        _e(
          d.add(const Duration(hours: 7)),
          'light.lamp',
          'on',
          automated: true,
        ),
    ];
    final habits = findHabits(entries, devices);
    final h = habits.single;
    expect(h.kind, HabitKind.time);
    expect(h.action.entityId, 'light.lamp');
    expect(h.action.service, 'turn_off');
    // 23:50, 00:00, 00:10 … average around midnight, not noon.
    final t = h.trigger as TimeTrigger;
    expect((t.hour, t.minute), anyOf((0, 0), (23, 55), (0, 5)));
    expect(h.weekdays, isNull);
    expect(h.seen, greaterThanOrEqualTo(12));
  });

  test('weekdays only, and nothing that unlocks', () {
    final entries = [
      for (final d in days)
        if (d.weekday > 5)
          _e(d.add(const Duration(hours: 11)), 'lock.door', 'unlocked')
        else ...[
          _e(d.add(const Duration(hours: 7, minutes: 5)), 'light.hall', 'on'),
          _e(
            d.add(const Duration(hours: 7, minutes: 6)),
            'lock.door',
            'unlocked',
          ),
        ],
    ];
    final h = findHabits(entries, devices).single;
    expect(h.weekdays, {1, 2, 3, 4, 5});
    expect((h.trigger as TimeTrigger).hour, 7);
    expect(h.action.entityId, 'light.hall');
  });

  test('a light after the door, in the evening only: when it is dark', () {
    final entries = [
      for (final d in days) ...[
        _e(
          d.add(const Duration(hours: 18, minutes: 3)),
          'binary_sensor.door',
          'on',
          user: false,
        ),
        _e(
          d.add(Duration(hours: 18, minutes: 4, seconds: d.day)),
          'light.hall',
          'on',
        ),
        // The door also opens in the morning without the light.
        _e(
          d.add(const Duration(hours: 8)),
          'binary_sensor.door',
          'on',
          user: false,
        ),
      ],
    ];
    final after = findHabits(
      entries,
      devices,
    ).where((h) => h.kind == HabitKind.after).single;
    expect(after.trigger, isA<DeviceTrigger>());
    expect((after.trigger as DeviceTrigger).entityId, 'binary_sensor.door');
    expect(after.automation.conditions.single, isA<SunCondition>());
    expect(after.seen, 14);
    expect(after.outOf, 28);
  });

  test('too little logbook, or too irregular: nothing', () {
    expect(
      findHabits([
        for (final d in days.take(3))
          _e(d.add(const Duration(hours: 22)), 'light.lamp', 'off'),
      ], devices),
      isEmpty,
    );
    expect(
      findHabits([
        for (final (i, d) in days.indexed)
          _e(d.add(Duration(hours: i * 5 % 24)), 'light.lamp', 'off'),
      ], devices),
      isEmpty,
    );
  });

  testWidgets('suggested in the demo home, opened in the editor, saved', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(900, 2000));
    await settle(tester, 10);
    final server = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    ).read(mockHomeAssistantServerProvider);
    await goTo(tester, AppRoutes.scenes);
    await settle(tester, 8);
    expect(find.byKey(const Key('habitSuggestions')), findsOneWidget);
    const offKey = 'habit-time|light.living_room_main|turn_off|22';
    const hallKey =
        'habit-after|binary_sensor.front_door|on|light.hallway|turn_on';
    expect(find.byKey(const Key(offKey)), findsOneWidget);
    expect(find.byKey(const Key(hallKey)), findsOneWidget);

    // "No thanks" hides it for good.
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key(hallKey)),
        matching: find.byType(TextButton),
      ),
    );
    await settle(tester, 2);
    expect(find.byKey(const Key(hallKey)), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key(offKey)),
        matching: find.byType(FilledButton),
      ),
    );
    await settle(tester, 4);
    await tester.ensureVisible(find.byKey(const Key('autoSave')));
    await tapKey(tester, 'autoSave');
    await settle(tester, 6);
    final saved = server.automations.values.last;
    expect(saved['triggers'], [
      {'trigger': 'time', 'at': '22:30:00'},
    ]);
    expect((saved['actions']! as List).single, {
      'action': 'light.turn_off',
      'target': {'entity_id': 'light.living_room_main'},
    });
    expect(find.byKey(const Key(offKey)), findsNothing);
    await unmount(tester);
  });
}
