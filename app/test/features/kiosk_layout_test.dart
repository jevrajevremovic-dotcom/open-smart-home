import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/kiosk/application/kiosk_controller.dart';
import 'package:open_smart_home/features/kiosk/data/kiosk_layout.dart';
import 'package:open_smart_home/integrations/home_assistant/home_assistant_providers.dart';

import '../widgets/app_widget_test.dart'
    show en, goTo, pumpApp, settle, tapKey, unmount;

List<String> ids(KioskLayout l) => [for (final p in l.panels) p.id];

void main() {
  test('flow into rows, move, resize and parse tolerantly', () {
    const l = KioskLayout.standard;
    expect(KioskLayout.rows(l.panels).map((r) => r.map((p) => p.id).toList()), [
      ['camera', 'weather', 'thermostat'],
      ['rooms', 'shortcuts', 'calendar'],
    ]);
    expect(ids(l.move('calendar', 'camera', after: false)).first, 'calendar');
    expect(ids(l.move('camera', 'rooms', after: true))[3], 'camera');
    expect(l.resize('weather', 20).panels[1].span, 12);
    expect(l.resize('weather', -20).panels[1].span, KioskLayout.minSpan);
    expect(l.toggleHeight('rooms').panels[3].height, 2);
    expect(l.remove('camera').panels, hasLength(5));
    final added = l.add(KioskPanelType.device, entityId: 'light.hallway');
    expect(added.panels.last.entityId, 'light.hallway');

    final parsed = KioskLayout.tryParse([
      {'id': 'a', 'type': 'weather', 'span': 99},
      {'id': 'a', 'type': 'rooms'}, // duplicate id
      {'id': 'b', 'type': 'nonsense'},
      'junk',
    ])!;
    expect(parsed.panels.single.span, 12);
    expect(KioskLayout.tryParse([]), isNull);
    expect(KioskLayout.tryParse(parsed.toJson()), parsed);
  });

  testWidgets('drag, resize, remove and add panels on the tablet', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(1280, 800));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    KioskLayout layout() =>
        container.read(kioskSettingsProvider).effectiveLayout;
    final server = container.read(mockHomeAssistantServerProvider);

    await goTo(tester, AppRoutes.settingsSection('kiosk'));
    await tapKey(tester, 'kioskEditLayoutTile');
    await settle(tester, 8);
    expect(find.byKey(const Key('kioskLayoutDone')), findsOneWidget);

    // Hold "weather" and drop it on the left half of "camera".
    final weather = find.byKey(const ValueKey('kioskPanel-weather'));
    final camera = find.byKey(const ValueKey('kioskPanel-camera'));
    final gesture = await tester.startGesture(tester.getCenter(weather));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getTopLeft(camera) + const Offset(10, 60));
    await tester.pump();
    await gesture.up();
    await settle(tester, 3);
    expect(ids(layout()).take(2), ['weather', 'camera']);

    await tester.tap(find.byKey(const ValueKey('kioskPanelWider-weather')));
    await settle(tester, 2);
    expect(layout().panels.first.span, 5);

    await tester.tap(find.byKey(const ValueKey('kioskPanelRemove-calendar')));
    await settle(tester, 2);
    expect(ids(layout()), isNot(contains('calendar')));

    await tapKey(tester, 'kioskAddPanel');
    await settle(tester, 3);
    await tester.tap(find.byKey(const ValueKey('kioskAdd-device')));
    await settle(tester, 3);
    await tester.enterText(find.byKey(const Key('kioskPanelSearch')), 'Hodnik');
    await settle(tester, 2);
    await tester.tap(find.byKey(const ValueKey('kioskPick-light.hallway')));
    await settle(tester, 3);
    expect(layout().panels.last.type, KioskPanelType.device);

    await tapKey(tester, 'kioskLayoutDone');
    await settle(tester, 3);
    expect(find.byKey(const Key('kioskLayoutDone')), findsNothing);

    // The new device panel works like a big button.
    expect(server.stateForTest('light.hallway'), 'off');
    await tester.tap(find.byKey(const ValueKey('kioskDevice-light.hallway')));
    await settle(tester, 6);
    expect(server.stateForTest('light.hallway'), 'on');
    await unmount(tester);
  });

  testWidgets('with a kiosk PIN, editing asks for it first', (tester) async {
    await pumpApp(tester, signedIn: true, size: const Size(1280, 800));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    await container.read(kioskSettingsProvider.notifier).setPin('2468');
    await goTo(tester, AppRoutes.settingsSection('kiosk'));
    await tapKey(tester, 'startKiosk');
    await settle(tester, 8);

    await tapKey(tester, 'kioskEditLayout');
    await settle(tester, 3);
    expect(find.text(en.kioskEnterPin), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '2468');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, 4);
    expect(find.byKey(const Key('kioskLayoutDone')), findsOneWidget);
    expect(
      container.read(kioskActiveProvider),
      isTrue,
      reason: 'still in kiosk mode',
    );
    await unmount(tester);
  });
}
