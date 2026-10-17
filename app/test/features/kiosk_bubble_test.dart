import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/dashboard/application/home_sentence.dart';
import 'package:open_smart_home/features/dashboard/application/home_summaries.dart';
import 'package:open_smart_home/features/kiosk/application/kiosk_controller.dart';
import 'package:open_smart_home/features/kiosk/data/kiosk_settings.dart';
import 'package:open_smart_home/features/weather/domain/weather.dart';
import 'package:open_smart_home/integrations/home_assistant/home_assistant_providers.dart';

import '../widgets/app_widget_test.dart'
    show en, goTo, pumpApp, settle, tapKey, unmount;

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  test('the home in one sentence, only from facts', () {
    final now = DateTime(2026, 10, 17, 21, 29);
    final text = homeSentence(
      en,
      now: now,
      summary: const DashboardSummary(
        lightsOn: 6,
        lightsTotal: 9,
        openingIds: ['binary_sensor.window'],
      ),
      weather: const WeatherNow(
        condition: WeatherCondition.partlyCloudy,
        temperature: 18.7,
      ),
      unlocked: const ['Front door'],
      alarm: 'Armed home',
    );
    expect(text, startsWith(en.homeSayTime('21:29')));
    expect(text, contains(en.homeSayLights(6)));
    expect(text, contains(en.homeSayOpen(1)));
    expect(text, contains(en.homeSayUnlocked('Front door')));
    expect(text, contains('18.7°'));

    final quiet = homeSentence(
      en,
      now: now,
      summary: const DashboardSummary(lightsTotal: 3),
    );
    expect(quiet, contains(en.homeSayLightsOff));
    expect(quiet, contains(en.homeSayClosed));
    expect(quiet, isNot(contains('Alarm')), reason: 'no alarm, not mentioned');
  });

  testWidgets('bubble kiosk: header, rooms, room window with light slider', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(1600, 1000));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    expect(container.read(kioskSettingsProvider).style, KioskStyle.bubble);
    final server = container.read(mockHomeAssistantServerProvider);
    container.read(kioskActiveProvider.notifier).enter();
    await goTo(tester, AppRoutes.kiosk);
    await settle(tester, 8);

    expect(find.byKey(const Key('kioskHomeSentence')), findsOneWidget);
    expect(find.text(en.kioskStatInside), findsOneWidget);
    expect(find.byKey(const ValueKey('kioskRoom-living_room')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kioskRoom-living_room')));
    await settle(tester, 4);
    expect(find.byKey(const Key('kioskRoomSheet')), findsOneWidget);
    final card = find.byKey(
      const ValueKey('bubbleLight-light.living_room_ambient'),
    );
    expect(card, findsOneWidget);
    // Room name left out: "Ambient", not "Living room – ambient".
    expect(
      find.descendant(of: card, matching: find.textContaining('–')),
      findsNothing,
    );

    // Drag the slider to the far left: brightness goes down.
    final slider = find.byKey(
      const ValueKey('bubbleLightSlider-light.living_room_ambient'),
    );
    await tester.drag(slider, const Offset(-600, 0));
    await settle(tester, 6);
    final brightness =
        (server.states.firstWhere(
              (s) => s['entity_id'] == 'light.living_room_ambient',
            )['attributes']!
            as Map)['brightness'];
    expect((brightness as num) < 128, isTrue, reason: 'was 50 %');

    await tapKey(tester, 'kioskRoomClose');
    await settle(tester, 3);
    expect(find.byKey(const Key('kioskRoomSheet')), findsNothing);
    await unmount(tester);
  });

  testWidgets('glass is still there for whoever prefers it', (tester) async {
    await pumpApp(tester, signedIn: true, size: const Size(1600, 1000));
    await settle(tester, 10);
    await goTo(tester, AppRoutes.settingsSection('kiosk'));
    await settle(tester, 2);
    await tester.tap(find.text(en.kioskStyleGlass));
    await settle(tester, 2);
    expect(find.byKey(const Key('kioskBackground')), findsOneWidget);
    await tapKey(tester, 'startKiosk');
    await settle(tester, 6);
    expect(find.byKey(const Key('kioskHomeSentence')), findsNothing);
    expect(find.text(en.kioskDoorsWindows), findsOneWidget);
    await unmount(tester);
  });
}
