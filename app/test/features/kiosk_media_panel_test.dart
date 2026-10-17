import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/kiosk/application/kiosk_controller.dart';
import 'package:open_smart_home/features/kiosk/data/kiosk_layout.dart';
import 'package:open_smart_home/integrations/home_assistant/home_assistant_providers.dart';

import '../widgets/app_widget_test.dart'
    show goTo, pumpApp, settle, tapKey, unmount;

void main() {
  testWidgets('music player as a kiosk panel', (tester) async {
    await pumpApp(tester, signedIn: true, size: const Size(1600, 1000));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    final server = container.read(mockHomeAssistantServerProvider);
    String state() => server.stateForTest('media_player.living_room_speaker')!;
    String title() =>
        (server.states.firstWhere(
                  (s) => s['entity_id'] == 'media_player.living_room_speaker',
                )['attributes']!
                as Map)['media_title']!
            as String;

    await container
        .read(kioskSettingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            layout: const KioskLayout([
              KioskPanel(id: 'm', type: KioskPanelType.media, span: 6),
              KioskPanel(id: 'r', type: KioskPanelType.rooms, span: 6),
            ]),
          ),
        );
    container.read(kioskActiveProvider.notifier).enter();
    await goTo(tester, AppRoutes.kiosk);
    await settle(tester, 8);

    final panel = find.byKey(const Key('kioskMediaPanel'));
    expect(panel, findsOneWidget);
    expect(
      find.descendant(of: panel, matching: find.text('Kafa i kiša')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('kioskMediaProgress')), findsOneWidget);

    await tapKey(tester, 'kioskMediaPlayPause');
    await settle(tester, 4);
    expect(state(), 'paused');

    await tapKey(tester, 'kioskMediaNext');
    await settle(tester, 4);
    expect(title(), 'Tiho jutro');

    // The artwork opens the full player.
    await tapKey(tester, 'kioskMediaOpen');
    await settle(tester, 4);
    expect(find.byKey(const Key('mediaSheet')), findsOneWidget);
    await unmount(tester);
  });
}
