import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/automations/domain/ai_automation.dart';
import 'package:open_smart_home/integrations/home_assistant/home_assistant_providers.dart';

import '../widgets/app_widget_test.dart'
    show goTo, pumpApp, settle, tapKey, unmount;

void main() {
  const entities = {
    'light.hallway',
    'binary_sensor.hallway_motion',
    'lock.door',
  };
  const services = {
    'light': {'turn_on', 'turn_off'},
    'lock': {'unlock', 'lock'},
    'notify': {'mobile_app_phone'},
  };
  AiDraft parse(Object? data) =>
      parseAiDraft(data, entities: entities, services: services);

  test('reads JSON from text, a code block or an object', () {
    const json =
        '{"alias": "A", "triggers": [{"trigger": "state", '
        '"entity_id": "binary_sensor.hallway_motion", "to": "on"}], '
        '"actions": [{"action": "light.turn_on", '
        '"target": {"entity_id": ["light.hallway"]}}]}';
    for (final data in [json, 'Evo:\n```json\n$json\n```', 'Sure! $json']) {
      final d = parse(data);
      expect(d.alias, 'A');
      expect(d.canSave, isTrue);
      expect(d.config['mode'], 'single');
      expect(d.config['conditions'], isEmpty);
    }
    expect(
      parse({
        'trigger': [
          {'trigger': 'time', 'at': '07:00:00'},
        ],
        'action': [
          {
            'action': 'notify.mobile_app_phone',
            'data': {'message': 'Hi'},
          },
        ],
      }).canSave,
      isTrue,
      reason: 'singular keys of older syntax',
    );
  });

  test('made-up devices and actions, blocked and sensitive ones', () {
    final d = parse({
      'triggers': [
        {'trigger': 'state', 'entity_id': 'binary_sensor.ghost', 'to': 'on'},
      ],
      'conditions': [
        {
          'condition': 'state',
          'entity_id': 'sun.sun',
          'state': 'below_horizon',
        },
      ],
      'actions': [
        {
          'action': 'lock.unlock',
          'target': {'entity_id': 'lock.door'},
        },
        {'action': 'light.blink'},
        {'action': 'shell_command.wipe'},
        {'action': 'homeassistant.restart'},
      ],
    });
    expect(d.unknownEntities, ['binary_sensor.ghost']);
    expect(d.unknownActions, ['light.blink']);
    expect(d.blocked, ['homeassistant.restart', 'shell_command.wipe']);
    expect(d.sensitive, ['lock.unlock']);
    expect(d.canSave, isFalse);
  });

  test('not an automation; the AI says what is missing', () {
    expect(() => parse('I cannot help'), throwsA(isA<AiDraftError>()));
    expect(
      () => parse({'triggers': [], 'actions': []}),
      throwsA(isA<AiDraftError>()),
    );
    expect(
      () => parse('{"error": "no sprinkler"}'),
      throwsA(
        isA<AiDraftError>().having((e) => e.message, 'message', 'no sprinkler'),
      ),
    );
  });

  testWidgets('describe it, review it, save it', (tester) async {
    await pumpApp(tester, signedIn: true, size: const Size(900, 1600));
    await settle(tester, 10);
    final server = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    ).read(mockHomeAssistantServerProvider);
    await goTo(tester, AppRoutes.scenes);
    await settle(tester, 6);
    await tapKey(tester, 'newAiAutomation');
    await settle(tester, 4);
    await tester.enterText(
      find.byKey(const Key('aiAutoText')),
      'Noću u hodniku upali svetlo',
    );
    await tapKey(tester, 'aiAutoAsk');
    await settle(tester, 6);
    expect(find.byKey(const Key('aiAutoDraft')), findsOneWidget);
    expect(find.text('Noćno svetlo u hodniku'), findsOneWidget);
    final sent = server.aiTaskRequests.single;
    expect(sent, contains('Noću u hodniku upali svetlo'));
    expect(sent, contains('light.hallway: Hodnik'));
    expect(
      server.automations.keys.where((k) => k.startsWith('osh_ai_')),
      isEmpty,
    );

    await tester.ensureVisible(find.byKey(const Key('aiAutoSave')));
    await tapKey(tester, 'aiAutoSave');
    await settle(tester, 6);
    final saved = server.automations.entries
        .where((e) => e.key.startsWith('osh_ai_'))
        .single
        .value;
    expect(saved['alias'], 'Noćno svetlo u hodniku');

    // A draft with a made-up device cannot be saved.
    server.aiTaskAnswer = {
      'triggers': [
        {'trigger': 'state', 'entity_id': 'binary_sensor.ghost', 'to': 'on'},
      ],
      'actions': [
        {
          'action': 'light.turn_on',
          'target': {'entity_id': 'light.hallway'},
        },
      ],
    };
    await tapKey(tester, 'newAiAutomation');
    await settle(tester, 4);
    await tester.enterText(find.byKey(const Key('aiAutoText')), 'x');
    await tapKey(tester, 'aiAutoAsk');
    await settle(tester, 6);
    expect(find.byKey(const Key('aiAutoUnknownEntities')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('aiAutoSave')));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('aiAutoSave')))
          .onPressed,
      isNull,
    );
    await unmount(tester);
  });
}
