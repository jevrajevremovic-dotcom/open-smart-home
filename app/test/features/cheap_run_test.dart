import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/energy/application/cheap_run.dart';
import 'package:open_smart_home/integrations/home_assistant/home_assistant_providers.dart';

import '../widgets/app_widget_test.dart'
    show goTo, pumpApp, settle, tapKey, unmount;

void main() {
  testWidgets('a plug scheduled for the cheapest hours, then cancelled', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(900, 2400));
    await settle(tester, 10);
    final server = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    ).read(mockHomeAssistantServerProvider);
    await goTo(tester, AppRoutes.device('switch.washer_plug'));
    await settle(tester, 8);
    expect(find.byKey(const Key('cheapRun')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('cheapRunHours-3')));
    await tester.tap(find.byKey(const ValueKey('cheapRunHours-3')));
    await settle(tester, 2);
    await tester.ensureVisible(find.byKey(const Key('cheapRunPlan')));
    await tapKey(tester, 'cheapRunPlan');
    await settle(tester, 14);

    final id = cheapRunId('switch.washer_plug');
    final config = server.automations[id]!;
    final variables = config['variables']! as Map;
    final start = DateTime.parse(variables['osh_start']! as String);
    final end = DateTime.parse(variables['osh_end']! as String);
    expect(end.difference(start), const Duration(hours: 3));
    final triggers = config['triggers']! as List;
    expect(triggers.last, containsPair('id', 'end'));
    final choose =
        ((config['actions']! as List).single as Map)['choose']! as List;
    final ending = (choose.last as Map)['sequence']! as List;
    expect(ending.last, {
      'action': 'automation.turn_off',
      'target': {'entity_id': '{{ this.entity_id }}'},
    });
    expect(find.byKey(const Key('cheapRunPlanned')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('cheapRunCancel')));
    await tapKey(tester, 'cheapRunCancel');
    await settle(tester, 6);
    expect(server.automations.containsKey(id), isFalse);
    expect(find.byKey(const Key('cheapRunPlan')), findsOneWidget);
    await unmount(tester);
  });
}
