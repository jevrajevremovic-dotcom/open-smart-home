import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/localization/generated/app_localizations_en.dart';
import 'package:open_smart_home/features/extras/batteries.dart';
import 'package:open_smart_home/features/extras/battery_forecast.dart';
import 'package:open_smart_home/integrations/home_assistant/home_assistant_providers.dart';

import '../../widgets/app_widget_test.dart'
    show en, pumpApp, settle, tapKey, unmount;

void main() {
  test('days left: a line since the battery was last replaced', () {
    final t0 = DateTime(2026, 9);
    List<(DateTime, double)> line(double from, double perDay, int days) => [
      for (var i = 0; i < days; i++)
        (t0.add(Duration(days: i)), from - perDay * i),
    ];
    // 1 % a day, now at 35 %: 30 days to 5 %.
    expect(batteryDaysLeft(line(65, 1, 31)), closeTo(30, 0.01));
    // An old battery before a jump up is left out.
    final replaced = [
      ...line(12, 0.2, 10),
      for (final (t, v) in line(100, 2, 20))
        (t.add(const Duration(days: 10)), v),
    ];
    expect(batteryDaysLeft(replaced), closeTo((62 - 5) / 2, 0.01));
    // Flat, too short, or too little change: no guess.
    expect(batteryDaysLeft(line(80, 0, 30)), isNull);
    expect(batteryDaysLeft(line(80, 1, 5)), isNull);
    expect(batteryDaysLeft(line(80, 0.05, 30)), isNull);
    expect(
      parseMeans({
        'sensor.x': [
          {'start': 1700000000000, 'mean': 50},
          {'start': '2026-01-01T00:00:00Z', 'mean': 49.5},
          {'start': 1700000000000},
        ],
      })['sensor.x'],
      hasLength(2),
    );
  });

  test('reminder: any battery sensor below the line, then the messages', () {
    final c = batteryReminderAutomation(
      AppLocalizationsEn(),
      sensorIds: ['sensor.a_battery', 'sensor.b_battery'],
      notify: ['notify.mobile_app_marko'],
    );
    expect(c['triggers'], [
      {
        'trigger': 'numeric_state',
        'entity_id': ['sensor.a_battery', 'sensor.b_battery'],
        'below': batteryLowPercent + 1,
      },
    ]);
    final actions = c['actions']! as List;
    expect((actions.first as Map)['action'], 'notify.mobile_app_marko');
    expect((actions.last as Map)['action'], 'persistent_notification.create');
    expect(
      '${(actions.last as Map)['data']}',
      contains('{{ trigger.to_state.name }}'),
    );
  });

  testWidgets('More → Batteries: emptiest first, reminder saved in HA', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(800, 1600));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    final server = container.read(mockHomeAssistantServerProvider);

    await tapKey(tester, 'openExtras');
    await settle(tester, 2);
    await tapKey(tester, 'extraBatteries');
    await settle(tester, 3);
    expect(find.byKey(const Key('batteriesSheet')), findsOneWidget);
    final first = container.read(batteriesProvider).first;
    expect(first.percent, 8);
    expect(first.low, isTrue);
    expect(first.sensorId, 'sensor.bedroom_window_battery');
    expect(find.text('8 %'), findsOneWidget);
    // From the long-term statistics: the lock loses 1.2 % a day from 31 %.
    await settle(tester, 4);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('batteryLeft-lock.front_door')),
        matching: find.text(en.batteryLeftWeeks(3)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('batteryLeft-binary_sensor.bedroom_window'),
        ),
        matching: find.text(en.batteryLeftDays(6)),
      ),
      findsOneWidget,
    );

    await tapKey(tester, 'batteryReminder');
    await settle(tester, 4);
    expect(server.automations[batteryReminderId], isNotNull);
    expect(container.read(batteryReminderSetProvider), isTrue);
    expect(find.text(en.batteryReminder), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a reminder saved with old sensors is brought up to date', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(800, 1600));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    final server = container.read(mockHomeAssistantServerProvider);
    server.saveAutomation(
      batteryReminderId,
      batteryReminderAutomation(
        AppLocalizationsEn(),
        sensorIds: ['sensor.gone_battery'],
        notify: const [],
      ),
    );
    await settle(tester, 3);
    await tapKey(tester, 'openExtras');
    await settle(tester, 5);
    await tapKey(tester, 'extraBatteries');
    await settle(tester, 15);
    final trigger =
        (server.automations[batteryReminderId]!['triggers']! as List).first
            as Map;
    expect(trigger['entity_id'], [
      'sensor.bedroom_window_battery',
      'sensor.front_lock_battery',
    ]);
    await unmount(tester);
  });
}
