import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/localization/generated/app_localizations_en.dart';
import 'package:open_smart_home/features/recipes/recipes.dart';
import 'package:open_smart_home/integrations/home_assistant/home_assistant_providers.dart';

import '../../widgets/app_widget_test.dart'
    show pumpApp, settle, tapKey, unmount;

void main() {
  final en = AppLocalizationsEn();

  test('leak: wet sensor closes the valve, then the messages', () {
    const r = Recipe(
      kind: RecipeKind.leak,
      sensors: ['binary_sensor.kitchen_leak'],
      targets: ['valve.main_water', 'switch.pump'],
      phone: 'notify.mobile_app_marko',
    );
    final c = r.automation(en);
    expect(r.id, 'osh_recipe_leak');
    expect(c['triggers'], [
      {
        'trigger': 'state',
        'entity_id': ['binary_sensor.kitchen_leak'],
        'to': 'on',
      },
    ]);
    final actions = c['actions']! as List;
    expect((actions[0] as Map)['action'], 'valve.close_valve');
    expect((actions[1] as Map)['action'], 'switch.turn_off');
    expect((actions[2] as Map)['action'], 'notify.mobile_app_marko');
    expect((actions[3] as Map)['action'], 'persistent_notification.create');
    expect(Recipe.fromAutomation(c)!.targets, r.targets);
  });

  test('follow presence: on with movement, off after the quiet minutes', () {
    const r = Recipe(
      kind: RecipeKind.followPresence,
      sensors: ['binary_sensor.hallway_motion'],
      targets: ['light.hallway'],
      minutes: 4,
      onlyAtNight: true,
    );
    final c = r.automation(en);
    expect(r.id, 'osh_recipe_followPresence_binary_sensor_hallway_motion');
    expect(c['mode'], 'restart');
    final triggers = c['triggers']! as List;
    expect((triggers[1] as Map)['for'], {'minutes': 4});
    final choose = ((c['actions']! as List).single as Map)['choose'] as List;
    expect(
      (choose.first as Map)['conditions'],
      contains(isA<Map<Object?, Object?>>()),
    );
    expect(Recipe.fromAutomation(c)!.onlyAtNight, isTrue);
  });

  test('last one out: nobody in zone.home', () {
    final c = const Recipe(kind: RecipeKind.lastOut).automation(en);
    expect((c['triggers']! as List).single, {
      'trigger': 'numeric_state',
      'entity_id': 'zone.home',
      'below': 1,
    });
  });

  test('escalation: ask the first phones, wait, then everyone, twice', () {
    const r = Recipe(
      kind: RecipeKind.escalation,
      sensors: ['binary_sensor.kitchen_leak', 'alarm_control_panel.home'],
      targets: ['notify.mobile_app_marko'],
      others: ['notify.mobile_app_ana'],
      minutes: 3,
    );
    final c = r.automation(en);
    expect(r.id, 'osh_recipe_escalation');
    final triggers = c['triggers']! as List;
    expect((triggers[0] as Map)['to'], 'on');
    expect((triggers[1] as Map)['to'], 'triggered');
    final actions = c['actions']! as List;
    final first = actions.first as Map;
    expect(first['action'], 'notify.mobile_app_marko');
    final buttons = ((first['data']! as Map)['data']! as Map)['actions'];
    expect(buttons, [
      {'action': escalationAck, 'title': en.escalationAck},
    ]);
    final wait = actions[2] as Map;
    expect(wait['timeout'], {'minutes': 3});
    expect(((wait['wait_for_trigger']! as List).single as Map)['event_data'], {
      'action': escalationAck,
    });
    final branch = actions[3] as Map;
    final then = branch['then']! as List;
    // Nobody answered: both phones are asked.
    expect(
      [for (final a in then.take(2)) (a as Map)['action']],
      ['notify.mobile_app_marko', 'notify.mobile_app_ana'],
    );
    // Answered: the question is cleared everywhere.
    final done = branch['else']! as List;
    expect(
      ((done.first as Map)['data']! as Map)['message'],
      'clear_notification',
    );
    expect(Recipe.fromAutomation(c)!.others, ['notify.mobile_app_ana']);
  });

  testWidgets('More → Recipes: a leak recipe saved, edited, removed', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(800, 1600));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    final server = container.read(mockHomeAssistantServerProvider);
    await tapKey(tester, 'openExtras');
    await settle(tester, 5);
    await tapKey(tester, 'extraRecipes');
    await settle(tester, 4);
    await tapKey(tester, 'recipe-leak');
    await settle(tester, 4);
    await tapKey(tester, 'recipePick-binary_sensor.kitchen_leak');
    await tapKey(tester, 'recipePick-valve.main_water');
    await settle(tester);
    await tapKey(tester, 'recipeSave');
    await settle(tester, 6);
    final saved = server.automations['osh_recipe_leak']!;
    expect(Recipe.fromAutomation(saved)!.targets, ['valve.main_water']);
    expect(container.read(savedRecipeIdsProvider), ['osh_recipe_leak']);

    await tapKey(tester, 'recipeRemove-osh_recipe_leak');
    await settle(tester, 4);
    expect(server.automations['osh_recipe_leak'], isNull);
    await unmount(tester);
  });
}
