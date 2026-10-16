import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/kiosk/application/kiosk_controller.dart';
import 'package:open_smart_home/features/kiosk/data/kiosk_layout.dart';
import 'package:open_smart_home/features/todo/todo_lists.dart';
import 'package:open_smart_home/integrations/home_assistant/home_assistant_providers.dart';
import 'package:open_smart_home/integrations/home_assistant/mock/mock_home_assistant.dart';

import '../widgets/app_widget_test.dart'
    show goTo, pumpApp, settle, tapKey, unmount;

void main() {
  test('items are read as Home Assistant sends them', () {
    final items = TodoItem.listFrom({
      'items': [
        {'uid': 'a', 'summary': 'Mleko', 'status': 'needs_action'},
        {
          'uid': 'b',
          'summary': 'Hleb',
          'status': 'completed',
          'due': '2026-11-01',
        },
        {'summary': 'no uid'},
      ],
    });
    expect(items.map((i) => i.summary), ['Mleko', 'Hleb']);
    expect(items[1].completed, isTrue);
    expect(items[1].due, '2026-11-01');
    expect(TodoItem.listFrom(null), isEmpty);
  });

  List<Map<String, Object?>> shopping(MockHomeAssistantServer s) =>
      s.todoItems['todo.shopping_list']!;
  Map<String, Object?>? named(MockHomeAssistantServer s, String summary) =>
      shopping(s).where((i) => i['summary'] == summary).firstOrNull;

  testWidgets('shopping list: add, check off, delete, clear done', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(800, 1600));
    await settle(tester, 10);
    final server = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    ).read(mockHomeAssistantServerProvider);

    // Home: the card lists what is still to buy.
    expect(find.text('Mleko, Hleb, Kafa'), findsOneWidget);
    await tapKey(tester, 'todoCard-todo.shopping_list');
    await settle(tester, 4);

    await tester.enterText(find.byKey(const Key('todoAddField')), 'Sir');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, 4);
    expect(named(server, 'Sir')?['status'], 'needs_action');
    expect(server.stateForTest('todo.shopping_list'), '4');
    expect(find.text('Sir'), findsOneWidget, reason: 'live update');

    await tester.tap(find.byKey(const ValueKey('todoItem-s1')));
    await settle(tester, 4);
    expect(named(server, 'Mleko')?['status'], 'completed');

    await tester.timedDrag(
      find.byKey(const ValueKey('todoDismiss-s2')),
      const Offset(-450, 0),
      const Duration(milliseconds: 400),
    );
    await settle(tester, 15);
    expect(named(server, 'Hleb'), isNull);

    await tapKey(tester, 'todoShowDone');
    await settle(tester, 2);
    expect(find.text('Mleko'), findsOneWidget);
    await tapKey(tester, 'todoClearDone');
    await settle(tester, 4);
    expect(shopping(server).any((i) => i['status'] == 'completed'), isFalse);

    // The other list.
    await tapKey(tester, 'todoList-todo.chores');
    await settle(tester, 4);
    expect(find.text('Zameniti filter klime'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a list on the wall panel: tap checks off, + adds', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(1600, 1000));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    final server = container.read(mockHomeAssistantServerProvider);
    await container
        .read(kioskSettingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            layout: const KioskLayout([
              KioskPanel(id: 'l', type: KioskPanelType.lists, span: 6),
              KioskPanel(id: 'w', type: KioskPanelType.weather, span: 6),
            ]),
          ),
        );
    container.read(kioskActiveProvider.notifier).enter();
    await goTo(tester, AppRoutes.kiosk);
    await settle(tester, 8);

    expect(find.text('Spisak za kupovinu'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('kioskTodo-s3')));
    await settle(tester, 4);
    expect(named(server, 'Kafa')?['status'], 'completed');
    expect(find.byKey(const ValueKey('kioskTodo-s3')), findsNothing);

    await tapKey(tester, 'kioskTodoAdd');
    await settle(tester, 2);
    await tester.enterText(find.byKey(const Key('kioskTodoField')), 'Banane');
    await tapKey(tester, 'kioskTodoSave');
    await settle(tester, 4);
    expect(named(server, 'Banane'), isNotNull);
    expect(find.text('Banane'), findsOneWidget);
    await unmount(tester);
  });
}
