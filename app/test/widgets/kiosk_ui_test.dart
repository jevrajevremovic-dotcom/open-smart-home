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
      expect(find.text(en.summaryTemperature), findsOneWidget);

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
    expect(
      find.byType(VerticalDivider),
      findsNWidgets(2),
      reason: 'rail divider + pane divider',
    );
    await unmount(tester);
  });
}
