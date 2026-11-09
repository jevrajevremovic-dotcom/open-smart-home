import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/localization/generated/app_localizations_en.dart';
import 'package:open_smart_home/features/recipes/recipes.dart';
import 'package:open_smart_home/features/simple_mode/simple_mode.dart';
import 'package:open_smart_home/integrations/home_assistant/home_assistant_providers.dart';

import '../../widgets/app_widget_test.dart'
    show pumpApp, settle, tapKey, unmount;

void main() {
  final en = AppLocalizationsEn();

  test('check-in: from six, waits for "I\'m fine" until the time', () {
    final c = const Recipe(
      kind: RecipeKind.checkIn,
      targets: ['notify.mobile_app_ana'],
      who: 'Baka',
      at: '10:30',
    ).automation(en);
    expect((c['triggers']! as List).single, {
      'trigger': 'time',
      'at': '06:00:00',
    });
    final actions = c['actions']! as List;
    final wait = actions[0] as Map;
    expect(wait['timeout'], '04:30:00');
    expect(
      ((wait['wait_for_trigger']! as List).single as Map)['event_type'],
      careCheckInEvent,
    );
    // Checked in: nothing more happens.
    expect((actions[1] as Map)['value_template'], '{{ wait.trigger is none }}');
    expect((actions[2] as Map)['action'], 'notify.mobile_app_ana');
  });

  test('help: the button\'s event; inactivity: all still, daytime', () {
    final help = const Recipe(
      kind: RecipeKind.help,
      targets: ['notify.mobile_app_ana'],
    ).automation(en);
    expect((help['triggers']! as List).single, {
      'trigger': 'event',
      'event_type': careHelpEvent,
    });
    final still = const Recipe(
      kind: RecipeKind.inactivity,
      sensors: ['binary_sensor.hallway_motion'],
      targets: ['notify.mobile_app_ana'],
      minutes: 180,
    ).automation(en);
    final trigger = (still['triggers']! as List).single as Map;
    expect(trigger['for'], {'minutes': 180});
    expect((still['conditions']! as List).last, {
      'condition': 'time',
      'after': '08:00:00',
      'before': '22:00:00',
    });
  });

  testWidgets('simple screen: "I\'m fine" and "Help" reach Home Assistant', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(412, 915));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    final server = container.read(mockHomeAssistantServerProvider);
    final simple = container.read(simpleModeProvider.notifier);
    await simple.setItems(['light.living_room_main']);
    await simple.setCare(true, 'Baka');
    await simple.setEnabled(true);
    await settle(tester, 6);

    await tapKey(tester, 'careFine');
    await settle(tester, 6);
    expect(server.firedEvents.last, {
      'event_type': careCheckInEvent,
      'event_data': {'who': 'Baka'},
    });
    expect(
      server.notifications.values.map((n) => n['message']),
      contains(en.careFineMessage('Baka')),
    );

    await tapKey(tester, 'careHelp');
    await settle(tester, 2);
    await tapKey(tester, 'careHelpConfirm');
    await settle(tester, 6);
    expect(server.firedEvents.last['event_type'], careHelpEvent);
    await simple.setEnabled(false);
    await settle(tester, 2);
    await unmount(tester);
  });
}
