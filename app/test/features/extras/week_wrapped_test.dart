import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/extras/week_wrapped.dart';
import 'package:open_smart_home/integrations/home_assistant/models/ha_history.dart';

import '../../helpers.dart';
import '../../widgets/app_widget_test.dart'
    show en, goTo, pumpApp, settle, tapKey, unmount;

void main() {
  test('counts the week from the logbook', () {
    final monday = DateTime(2026, 10, 19, 8);
    HaLogbookEntry e(String id, String state, [int day = 0]) => HaLogbookEntry(
      when: monday.add(Duration(days: day)),
      entityId: id,
      name: id,
      state: state,
    );
    final s = weekStats([
      e('light.kitchen', 'on'),
      e('light.kitchen', 'off'),
      e('light.kitchen', 'on', 2),
      e('light.hall', 'on', 2),
      e('person.ana', 'home', 2),
      e('person.ana', 'not_home', 3),
      e('person.ana', 'home', 3),
      e('person.marko', 'home', 4),
      e('lock.front', 'unlocked', 2),
      e('lock.front', 'locked', 2),
    ], const {});
    expect(s.lightsOn, 3);
    expect(s.topLight, 'light.kitchen');
    expect(s.topLightCount, 2);
    expect(s.arrivals, {'person.ana': 2, 'person.marko': 1});
    expect(s.unlocks, 1);
    expect(s.busiestDay, DateTime.wednesday);
    // Doors need their device class (unknown devices here): none counted.
    expect(s.doorOpenings, 0);
  });

  test('the doorbell, and what was left on longest', () {
    final t = DateTime(2026, 10, 19, 8);
    HaLogbookEntry e(String id, String state, Duration at) =>
        HaLogbookEntry(when: t.add(at), entityId: id, name: id, state: state);
    final s = weekStats([
      e('light.kitchen', 'on', Duration.zero),
      e('light.kitchen', 'off', const Duration(hours: 9, minutes: 30)),
      e('light.hall', 'on', Duration.zero),
      e('light.hall', 'off', const Duration(hours: 2)),
      e('binary_sensor.doorbell_button', 'on', const Duration(hours: 1)),
      e('binary_sensor.doorbell_button', 'off', const Duration(hours: 1)),
      e('binary_sensor.doorbell_button', 'on', const Duration(hours: 5)),
    ], const {});
    expect(s.doorbell, 2);
    final (name, open, light) = s.longestOpen!;
    expect(
      (name, open, light),
      ('light.kitchen', const Duration(hours: 9, minutes: 30), true),
    );
    expect(s.isEmpty, isFalse);
    final body = weekReportBody(en, s);
    expect(body, contains(en.weekReportDoorbell(2)));
    expect(body, contains(en.weekReportLongest('light.kitchen', '9 h 30 min')));
  });

  test('the weekly notification: from Sunday 19:00, once', () {
    final sunday = DateTime(2026, 11, 8, 19);
    expect(weekReportDue(DateTime(2026, 11, 8, 20)), sunday);
    expect(weekReportDue(DateTime(2026, 11, 10, 9)), sunday);
    expect(
      weekReportDue(DateTime(2026, 11, 8, 18)),
      sunday.subtract(const Duration(days: 7)),
    );
    expect(weekReportPending(DateTime(2026, 11, 8, 18), null), isFalse);
    expect(weekReportPending(DateTime(2026, 11, 8, 19, 5), null), isTrue);
    expect(
      weekReportPending(DateTime(2026, 11, 9, 8), DateTime(2026, 11, 8, 19, 5)),
      isFalse,
      reason: 'already sent',
    );
    expect(
      weekReportPending(DateTime(2026, 11, 12, 8), null),
      isFalse,
      reason: 'too late in the week',
    );
  });

  testWidgets('This week: a story, card by card, then closes', (tester) async {
    await pumpApp(tester, signedIn: true, size: const Size(800, 1600));
    await settle(tester, 10);
    await tapKey(tester, 'openExtras');
    await settle(tester, 5);
    await tapKey(tester, 'extraWrapped');
    await settle(tester, 10);
    expect(find.byKey(const Key('wrappedScreen')), findsOneWidget);
    expect(find.text(en.wrappedIntro), findsOneWidget);
    for (var i = 0; i < 12; i++) {
      if (find.byKey(const Key('wrappedScreen')).evaluate().isEmpty) break;
      await tester.tapAt(const Offset(700, 800));
      await settle(tester, 5);
    }
    expect(find.byKey(const Key('wrappedScreen')), findsNothing);
    await unmount(tester);
  });

  testWidgets('weekly summary: opt in, the notification opens the story', (
    tester,
  ) async {
    final alerts = FakeAlertNotifier();
    await pumpApp(
      tester,
      signedIn: true,
      size: const Size(800, 1600),
      alerts: alerts,
    );
    await settle(tester, 10);
    await goTo(tester, AppRoutes.settingsSection('notifications'));
    await tapKey(tester, 'weekReportSwitch');
    await settle(tester, 4);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('weekReportSwitch')))
          .value,
      isTrue,
    );
    alerts.tap(weekReportPayload);
    await settle(tester, 10);
    expect(find.byKey(const Key('wrappedScreen')), findsOneWidget);
    await unmount(tester);
  });
}
