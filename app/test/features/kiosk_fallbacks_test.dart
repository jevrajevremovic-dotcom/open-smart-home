import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/features/kiosk/application/kiosk_controller.dart';
import 'package:open_smart_home/features/kiosk/data/kiosk_layout.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/devices/domain/device_command.dart';
import 'package:open_smart_home/integrations/home_assistant/mappers/ha_command_translator.dart';
import 'package:open_smart_home/integrations/home_assistant/mappers/ha_device_mapper.dart';
import 'package:open_smart_home/integrations/home_assistant/mock/mock_fixtures.dart';
import 'package:open_smart_home/integrations/home_assistant/mock/mock_home_assistant.dart';
import 'package:open_smart_home/integrations/home_assistant/models/ha_models.dart';
import 'package:open_smart_home/integrations/home_assistant/models/ha_registry.dart';

import '../widgets/app_widget_test.dart'
    show en, goTo, pumpApp, settle, tapKey, unmount;

/// A Home Assistant without a weather entity and without calendars.
MockHomeAssistantServer bareServer() => MockHomeAssistantServer(
  states: [
    for (final s in buildMockStates(DateTime.now()))
      if (!(s['entity_id']! as String).startsWith('weather.')) s,
  ],
)..calendars = [];

Future<void> startKiosk(WidgetTester tester) async {
  await goTo(tester, AppRoutes.settingsSection('kiosk'));
  await tapKey(tester, 'startKiosk');
  await settle(tester, 20);
}

void main() {
  test('select_source is validated against the source list', () {
    final tv = const HaDeviceMapper().map(
      const HaEntityState(
        entityId: 'media_player.tv',
        state: 'on',
        attributes: {
          'source_list': ['HDMI 1', 'TV'],
          'supported_features': 2048,
        },
      ),
      HaRegistries.empty,
    );
    const t = HaCommandTranslator();
    final call = t.translate(tv, const SelectSource('HDMI 1'));
    expect((call.service, call.data['source']), ('select_source', 'HDMI 1'));
    expect(() => t.translate(tv, const SelectSource('USB')), throwsA(anything));
  });

  testWidgets('kiosk without HA weather and calendars explains both', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signedIn: true,
      size: const Size(1280, 800),
      server: bareServer(),
    );
    await settle(tester, 10);
    // The weather panel (no longer in the standard layout) explains it.
    await ProviderScope.containerOf(tester.element(find.byType(SmartHomeApp)))
        .read(kioskSettingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            layout: KioskLayout.standard.add(KioskPanelType.weather),
          ),
        );
    await startKiosk(tester);
    expect(find.byKey(const Key('kioskWeatherMissing')), findsOneWidget);
    expect(find.text(en.kioskWeatherMissing), findsOneWidget);
    expect(find.byKey(const Key('kioskCalendar')), findsOneWidget);
    expect(find.byKey(const Key('calendarNone')), findsOneWidget);
    expect(find.byKey(const Key('calMonthTitle')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('home-location forecast after consent, shown in the kiosk', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signedIn: true,
      size: const Size(1280, 800),
      server: bareServer(),
    );
    await settle(tester, 10);
    await goTo(tester, AppRoutes.settingsSection('privacy'));
    await tapKey(tester, 'homeWeatherSwitch');
    await settle(tester, 2);
    expect(find.text(en.weatherHomeLocationDisclosure), findsOneWidget);
    await tapKey(tester, 'confirmHomeWeather');
    await settle(tester, 4);
    await startKiosk(tester);
    expect(find.byKey(const Key('kioskWeather')), findsOneWidget);
    expect(find.text(en.weatherMetAttribution), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('media sheet: switch player, power on, choose a source', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(1280, 800));
    await settle(tester, 10);
    await startKiosk(tester);
    await tapKey(tester, 'kioskNowPlaying');
    await settle(tester, 2);
    expect(find.byKey(const Key('mediaSheet')), findsOneWidget);
    expect(find.text('Kafa i kiša'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('mediaPlayer-media_player.living_room_tv')),
    );
    await settle(tester, 2);
    await tapKey(tester, 'mediaPower');
    await settle(tester, 4);
    await tapKey(tester, 'mediaSource');
    await settle(tester, 2);
    await tester.tap(find.text('HDMI 1').last);
    await settle(tester, 4);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('mediaSource')),
          )
          .initialValue,
      'HDMI 1',
    );
    await unmount(tester);
  });

  testWidgets('music card is there even without media players and explains', (
    tester,
  ) async {
    final server = MockHomeAssistantServer(
      states: [
        for (final s in buildMockStates(DateTime.now()))
          if (!(s['entity_id']! as String).startsWith('media_player.')) s,
      ],
    );
    await pumpApp(
      tester,
      signedIn: true,
      size: const Size(800, 1600),
      server: server,
    );
    await settle(tester, 10);
    final card = find.byKey(const Key('nowPlayingCard'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text(en.mediaNoPlayersShort)),
      findsOneWidget,
    );
    await tester.tap(card);
    await settle(tester, 3);
    expect(find.text(en.mediaNoPlayers), findsOneWidget);
    await unmount(tester);
  });
}
