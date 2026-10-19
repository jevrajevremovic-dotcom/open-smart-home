import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/kiosk/application/kiosk_controller.dart';
import 'package:open_smart_home/features/kiosk/data/kiosk_settings.dart';
import 'package:open_smart_home/features/weather/presentation/weather_card.dart';
import 'package:open_smart_home/integrations/home_assistant/home_assistant_providers.dart';

import '../widgets/app_widget_test.dart'
    show goTo, pumpApp, settle, tapKey, unmount;

void main() {
  test('columns is the default kiosk look', () {
    expect(const KioskSettings().style, KioskStyle.columns);
    expect(const KioskSettings().bubble, isTrue, reason: 'narrow fallback');
    expect(
      KioskSettings.fromJson(const {'style': 'glass'}).style,
      KioskStyle.glass,
    );
  });

  Future<ProviderContainer> kiosk(WidgetTester tester, Size size) async {
    await pumpApp(tester, signedIn: true, size: size);
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    await container
        .read(kioskSettingsProvider.notifier)
        .update((s) => s.copyWith(style: KioskStyle.columns));
    container.read(kioskActiveProvider.notifier).enter();
    await goTo(tester, AppRoutes.kiosk);
    await settle(tester, 8);
    return container;
  }

  testWidgets('rooms on the left, devices in the middle, details right', (
    tester,
  ) async {
    final container = await kiosk(tester, const Size(1600, 1000));
    final server = container.read(mockHomeAssistantServerProvider);
    expect(find.byKey(const Key('kioskColumns')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('kioskColumnsRoom-living_room')),
    );
    await settle(tester, 4);
    expect(
      tester.widget<Text>(find.byKey(const Key('kioskColumnsRoomTitle'))).data,
      'Dnevna soba',
    );
    // The room's climate is shown on the right, with the big dial.
    expect(
      tester.widget<Text>(find.byKey(const Key('kioskColumnsDetailName'))).data,
      'Klima dnevna soba',
    );
    await tapKey(tester, 'kioskIncreaseTemperature');
    await settle(tester, 20);
    final climate = server.states.firstWhere(
      (s) => s['entity_id'] == 'climate.living_room',
    );
    expect((climate['attributes']! as Map)['temperature'], 23.5);

    // The light's round icon switches it; the card shows it on the right.
    expect(server.stateForTest('light.living_room_main'), 'on');
    await tester.tap(
      find.byKey(const ValueKey('kioskColumnsToggle-light.living_room_main')),
    );
    await settle(tester, 4);
    expect(server.stateForTest('light.living_room_main'), 'off');
    await tester.tap(
      find.byKey(const ValueKey('kioskColumnsDevice-light.living_room_main')),
    );
    await settle(tester, 4);
    expect(
      tester.widget<Text>(find.byKey(const Key('kioskColumnsDetailName'))).data,
      'Dnevna soba – glavno svetlo',
    );

    // Another room.
    await tester.tap(find.byKey(const ValueKey('kioskColumnsRoom-kitchen')));
    await settle(tester, 4);
    expect(
      tester.widget<Text>(find.byKey(const Key('kioskColumnsRoomTitle'))).data,
      'Kuhinja',
    );

    // A scene from the left.
    await tester.tap(
      find.byKey(const ValueKey('kioskColumnsScene-scene.movie_night')),
    );
    await settle(tester, 4);

    // Search asks Assist.
    await tapKey(tester, 'kioskAssist');
    await settle(tester, 4);
    expect(find.byKey(const Key('assistSheet')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('this week\'s energy on the right', (tester) async {
    await kiosk(tester, const Size(1600, 1000));
    expect(find.byKey(const Key('kioskColumnsWeek')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('portrait or narrow screens fall back to the bubbles', (
    tester,
  ) async {
    await kiosk(tester, const Size(1000, 1400));
    expect(find.byKey(const Key('kioskColumns')), findsNothing);
    expect(find.byKey(const Key('kioskEditLayout')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('home overview first: weather, music, calendar; back to it', (
    tester,
  ) async {
    final container = await kiosk(tester, const Size(1600, 1000));
    expect(find.byKey(const Key('kioskColumnsOverview')), findsOneWidget);
    // Cameras first, then weather, music and the calendar.
    expect(find.byKey(const Key('kioskColumnsCameras')), findsOneWidget);
    final overview = find
        .descendant(
          of: find.byKey(const Key('kioskColumnsOverview')),
          matching: find.byType(Scrollable),
        )
        .first;
    double top(Finder f) => tester.getTopLeft(f).dy;
    for (final f in [
      find.byType(WeatherSection),
      find.byKey(const Key('nowPlayingCard')),
      find.byKey(const Key('kioskColumnsCalendar')),
    ]) {
      await tester.scrollUntilVisible(f, 300, scrollable: overview);
      expect(f, findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.byKey(const Key('kioskColumnsCameras')),
      -300,
      scrollable: overview,
    );
    expect(
      top(find.byKey(const Key('kioskColumnsCameras'))),
      lessThan(top(find.byType(WeatherSection))),
    );
    // The home's thermostat on the right.
    expect(
      tester.widget<Text>(find.byKey(const Key('kioskColumnsDetailName'))).data,
      'Klima dnevna soba',
    );

    await tester.tap(find.byKey(const ValueKey('kioskColumnsRoom-kitchen')));
    await settle(tester, 4);
    expect(find.byKey(const Key('kioskColumnsOverview')), findsNothing);
    await tapKey(tester, 'kioskColumnsHome');
    await settle(tester, 4);
    expect(find.byKey(const Key('kioskColumnsOverview')), findsOneWidget);

    // Left alone in a room, it goes back to the overview.
    await tester.tap(find.byKey(const ValueKey('kioskColumnsRoom-kitchen')));
    await settle(tester, 4);
    await tester.pump(container.read(kioskSettingsProvider).returnHomeAfter);
    await settle(tester, 4);
    expect(find.byKey(const Key('kioskColumnsOverview')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('quick controls: choose a light and a scene, use them', (
    tester,
  ) async {
    final container = await kiosk(tester, const Size(1600, 1000));
    final server = container.read(mockHomeAssistantServerProvider);
    expect(find.byKey(const Key('kioskQuickControls')), findsOneWidget);
    await tapKey(tester, 'kioskQuickControlsEdit');
    await settle(tester, 3);
    await tester.tap(
      find.byKey(const ValueKey('kioskQuickPick-light.hallway')),
    );
    await tester.enterText(find.byKey(const Key('kioskQuickSearch')), 'Film');
    await settle(tester, 2);
    await tester.tap(
      find.byKey(const ValueKey('kioskQuickPick-scene.movie_night')),
    );
    await tapKey(tester, 'kioskQuickSave');
    await settle(tester, 3);
    expect(container.read(kioskSettingsProvider).quickControls, [
      'light.hallway',
      'scene.movie_night',
    ]);
    expect(find.byKey(const ValueKey('kioskQuick-light.hallway')), findsOne);
    expect(
      find.byKey(const ValueKey('kioskQuick-scene.movie_night')),
      findsOne,
    );

    expect(server.stateForTest('light.hallway'), 'off');
    await tapKey(tester, 'kioskQuickSwitch-light.hallway');
    await settle(tester, 4);
    expect(server.stateForTest('light.hallway'), 'on');
    await unmount(tester);
  });

  testWidgets('cameras on the home overview, switchable, can be hidden', (
    tester,
  ) async {
    final container = await kiosk(tester, const Size(1600, 1000));
    expect(find.byKey(const Key('kioskColumnsCameras')), findsOneWidget);
    final driveway = find.byKey(
      const ValueKey('kioskColumnsCamera-camera.driveway'),
    );
    await tester.ensureVisible(driveway);
    await tester.tap(driveway);
    await settle(tester, 3);
    expect(tester.widget<ChoiceChip>(driveway).selected, isTrue);

    await container
        .read(kioskSettingsProvider.notifier)
        .update((s) => s.copyWith(showCameras: false));
    await settle(tester, 3);
    expect(find.byKey(const Key('kioskColumnsCameras')), findsNothing);
    await unmount(tester);
  });
}
