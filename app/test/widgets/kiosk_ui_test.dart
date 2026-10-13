import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/kiosk/data/kiosk_settings.dart';

import 'app_widget_test.dart' show en, goTo, pumpApp, settle, tapKey, unmount;

void main() {
  const tablet = Size(1280, 800);

  Future<void> startKiosk(WidgetTester tester) async {
    await goTo(tester, AppRoutes.settings);
    await tapKey(tester, 'startKiosk');
    await settle(tester, 5);
  }

  testWidgets(
    'kiosk dashboard: no standard navigation, deep links stay inside',
    (tester) async {
      await pumpApp(tester, signedIn: true, size: tablet);
      await settle(tester, 10);
      await startKiosk(tester);

      expect(find.byKey(const Key('kioskExit')), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      for (final key in [
        'kioskWeather',
        'kioskRooms',
        'kioskShortcuts',
        'kioskTargetTemperature',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
      expect(find.text(en.kioskDoorsWindows), findsOneWidget);

      await goTo(tester, AppRoutes.settings);
      expect(
        find.byKey(const Key('kioskExit')),
        findsOneWidget,
        reason: 'redirected back to kiosk',
      );
      await unmount(tester);
    },
  );

  testWidgets('exit with PIN; wrong PIN keeps kiosk', (tester) async {
    await pumpApp(tester, signedIn: true, size: tablet);
    await settle(tester, 10);
    await goTo(tester, AppRoutes.settings);

    // Set a PIN through the UI (entered twice).
    await tapKey(tester, 'kioskSetPin');
    await settle(tester, 2);
    await tester.enterText(find.byKey(const Key('pinField')), '4321');
    await tapKey(tester, 'pinSubmit');
    await settle(tester, 6); // first dialog closes, confirmation dialog opens
    expect(find.text(en.kioskPinConfirm), findsOneWidget);
    await tester.enterText(find.byKey(const Key('pinField')), '4321');
    await tapKey(tester, 'pinSubmit');
    await settle(tester, 2);
    expect(find.text(en.kioskPinSet), findsOneWidget);

    await tapKey(tester, 'startKiosk');
    await settle(tester, 5);

    await tapKey(tester, 'kioskExit');
    await settle(tester, 2);
    await tester.enterText(find.byKey(const Key('pinField')), '0000');
    await tapKey(tester, 'pinSubmit');
    await settle(tester, 2);
    expect(find.text(en.kioskWrongPin), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pinField')), '4321');
    await tapKey(tester, 'pinSubmit');
    await settle(tester, 5);
    expect(find.byKey(const Key('kioskExit')), findsNothing);
    expect(
      find.byType(NavigationRail),
      findsOneWidget,
      reason: 'back to the normal app',
    );
    await unmount(tester);
  });

  testWidgets('inactivity: back to kiosk dashboard, then dim; tap wakes', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: tablet);
    await settle(tester, 10);
    await startKiosk(tester);

    await goTo(tester, AppRoutes.device('light.living_room_main', kiosk: true));
    expect(find.text(en.brightness), findsOneWidget);

    // Default: return after 60 s, dim after 2 min.
    await tester.pump(
      const KioskSettings().returnHomeAfter + const Duration(seconds: 1),
    );
    await settle(tester, 3);
    expect(find.text(en.brightness), findsNothing);
    expect(find.byKey(const Key('kioskExit')), findsOneWidget);

    await tester.pump(const KioskSettings().dimAfter);
    await settle(tester, 2);
    expect(find.byKey(const Key('kioskScreensaver')), findsOneWidget);

    await tester.tap(find.byKey(const Key('kioskScreensaver')));
    await settle(tester, 2);
    expect(find.byKey(const Key('kioskScreensaver')), findsNothing);
    await unmount(tester);
  });

  testWidgets('tablet landscape dashboard uses two panes', (tester) async {
    await pumpApp(tester, signedIn: true, size: tablet);
    await settle(tester, 10);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byKey(const Key('dashboardStatusPane')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('kiosk thermostat: dial buttons and presets', (tester) async {
    await pumpApp(tester, signedIn: true, size: tablet);
    await settle(tester, 10);
    await startKiosk(tester);
    String target() => tester
        .widget<Text>(find.byKey(const Key('kioskTargetTemperature')))
        .data!;
    expect(target(), '23°');

    await tester.tap(find.byKey(const Key('kioskIncreaseTemperature')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('kioskIncreaseTemperature')));
    await tester.pump();
    expect(target(), '24°', reason: 'local value while debouncing');
    await settle(tester, 12);
    expect(target(), '24°', reason: 'confirmed by the server');

    await tester.tap(find.byTooltip(en.presetSleep));
    await settle(tester, 6);
    expect(
      tester.getSemantics(find.bySemanticsLabel(en.presetSleep)),
      isSemantics(isSelected: true),
    );
    await unmount(tester);
  });

  testWidgets('portrait kiosk stacks the panels without overflow', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(800, 1280));
    await settle(tester, 10);
    await startKiosk(tester);
    expect(find.byKey(const Key('kioskWeather')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('kioskRooms')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('kioskRooms')), findsOneWidget);
    await settle(tester, 4); // let in-flight requests finish
    await unmount(tester);
  });

  testWidgets('kiosk header: household and chosen status chips', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: tablet);
    await settle(tester, 10);
    await goTo(tester, AppRoutes.settings);
    await tapKey(tester, 'kioskStatusEntities');
    await settle(tester, 2);
    await tester.enterText(
      find.byKey(const Key('statusEntitiesSearch')),
      'Veš',
    );
    await settle(tester, 1);
    await tester.tap(
      find.byKey(const ValueKey('status-sensor.washing_machine_status')),
    );
    await tapKey(tester, 'statusEntitiesDone');
    await settle(tester, 2);
    expect(find.text(en.kioskStatusSelected(1)), findsOneWidget);

    await tapKey(tester, 'startKiosk');
    await settle(tester, 5);
    expect(find.byKey(const Key('kioskPeople')), findsOneWidget);
    expect(find.byTooltip('Marko: ${en.personHome}'), findsOneWidget);
    expect(find.byTooltip('Jelena: Posao'), findsOneWidget);
    expect(find.byTooltip('Ana: ${en.personAway}'), findsOneWidget);
    final chip = find.byKey(
      const ValueKey('chip-sensor.washing_machine_status'),
    );
    expect(chip, findsOneWidget);
    expect(
      find.descendant(of: chip, matching: find.textContaining('Završeno')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: chip,
        matching: find.textContaining(en.timeMinutesAgo(2)),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('kioskWeather')));
    await settle(tester, 4);
    expect(find.text(en.weatherForecastTitle), findsOneWidget);
    expect(find.byKey(const Key('kioskExit')), findsNothing);
    await unmount(tester);
  });

  testWidgets('kiosk with larger system text has no overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, signedIn: true, size: tablet);
    await settle(tester, 10);
    await startKiosk(tester);
    await settle(tester, 10);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
