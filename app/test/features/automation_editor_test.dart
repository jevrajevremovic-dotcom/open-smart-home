import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/automations/domain/simple_automation.dart';
import 'package:open_smart_home/integrations/home_assistant/home_assistant_providers.dart';

import '../widgets/app_widget_test.dart'
    show en, goTo, pumpApp, settle, tapKey, unmount;

void main() {
  test('config in the current HA format', () {
    final config = const SimpleAutomation(
      alias: 'Morning',
      trigger: TimeTrigger(7, 5, weekdays: {5, 1}),
      actions: [AutomationAction('light.hall', 'turn_on')],
    ).toConfig('123');
    expect(config['triggers'], [
      {'trigger': 'time', 'at': '07:05:00'},
    ]);
    expect(config['conditions'], [
      {
        'condition': 'time',
        'weekday': ['mon', 'fri'],
      },
    ]);
    expect(config['actions'], [
      {
        'action': 'light.turn_on',
        'target': {'entity_id': 'light.hall'},
      },
    ]);
    final sun = const SimpleAutomation(
      alias: 'x',
      trigger: SunTrigger(sunset: true, offsetMinutes: -30),
      actions: [],
    ).toConfig('1');
    expect((sun['triggers']! as List).single, {
      'trigger': 'sun',
      'event': 'sunset',
      'offset': '-00:30:00',
    });
    expect(sun['conditions'], isEmpty);
  });

  testWidgets('create "door opens → hallway light on", then delete it', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(800, 1600));
    await settle(tester, 10);
    final server = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    ).read(mockHomeAssistantServerProvider);

    await goTo(tester, AppRoutes.scenes);
    await tapKey(tester, 'newAutomation');
    await settle(tester, 4);

    await tapKey(tester, 'autoSave');
    await settle(tester, 2);
    expect(find.text(en.autoIncomplete), findsOneWidget);

    await tester.enterText(find.byKey(const Key('autoName')), 'Ulaz noću');
    await tester.tap(find.text(en.autoTriggerDevice));
    await settle(tester, 2);
    await tapKey(tester, 'autoTriggerDevice');
    await settle(tester, 2);
    await tester.enterText(find.byKey(const Key('pickSearch')), 'Ulazna');
    await settle(tester, 1);
    await tester.tap(
      find.byKey(const ValueKey('pick-binary_sensor.front_door')),
    );
    await settle(tester, 2);
    await tester.tap(find.byKey(const ValueKey('autoState-on')));
    await settle(tester, 1);

    await tapKey(tester, 'autoAddAction');
    await settle(tester, 2);
    await tester.enterText(find.byKey(const Key('pickSearch')), 'Hodnik');
    await settle(tester, 1);
    await tester.tap(find.byKey(const ValueKey('pick-light.hallway')));
    await settle(tester, 2);
    await tester.tap(find.byKey(const ValueKey('svc-turn_on')));
    await settle(tester, 2);

    await tapKey(tester, 'autoSave');
    await settle(tester, 8);
    expect(find.text(en.autoSaved), findsOneWidget);
    final config = server.automations.values.single;
    expect(config['alias'], 'Ulaz noću');
    expect((config['triggers']! as List).single, {
      'trigger': 'state',
      'entity_id': 'binary_sensor.front_door',
      'to': 'on',
    });
    expect(find.text('Ulaz noću'), findsOneWidget, reason: 'listed');

    await tester.tap(find.text('Ulaz noću'));
    await settle(tester, 4);
    await tapKey(tester, 'deleteAutomation');
    await settle(tester, 2);
    await tapKey(tester, 'confirmDeleteAutomation');
    await settle(tester, 8);
    expect(server.automations, isEmpty);
    expect(find.text('Ulaz noću'), findsNothing);
    await unmount(tester);
  });
}
