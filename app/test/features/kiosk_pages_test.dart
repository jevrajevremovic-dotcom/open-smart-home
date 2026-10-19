import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/kiosk/application/kiosk_controller.dart';
import 'package:open_smart_home/features/kiosk/data/kiosk_layout.dart';
import 'package:open_smart_home/features/kiosk/data/kiosk_settings.dart';
import 'package:open_smart_home/features/kiosk/presentation/kiosk_layout_view.dart';

import '../widgets/app_widget_test.dart'
    show en, goTo, pumpApp, settle, tapKey, unmount;

void main() {
  test('pages survive a round trip and keep their own layouts', () {
    final page = KioskPage.create(KioskPageTemplate.climateEnergy, 'Klima');
    final s = KioskSettings(pages: [page]);
    final back = KioskSettings.fromJson(s.toJson());
    expect(back.pages.single, page);
    expect(back.layoutOf(1).panels.map((p) => p.type), [
      KioskPanelType.thermostat,
      KioskPanelType.energy,
      KioskPanelType.weather,
    ]);
    expect(back.layoutOf(0), KioskLayout.standard);
    final edited = back.withLayoutOf(1, const KioskLayout([]));
    expect(edited.layoutOf(1).panels, isEmpty);
    expect(edited.layoutOf(0), KioskLayout.standard);
  });

  testWidgets('add a page, swipe between pages, rename, back home, delete', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(1600, 1000));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    await goTo(tester, AppRoutes.settingsSection('kiosk'));
    await tapKey(tester, 'startKiosk');
    await settle(tester, 6);
    expect(find.byKey(const Key('kioskPages')), findsNothing);

    await tapKey(tester, 'kioskEditLayout');
    await settle(tester, 3);
    await tapKey(tester, 'kioskAddPage');
    await settle(tester, 2);
    await tapKey(tester, 'kioskPageTemplate-climateEnergy');
    await settle(tester, 6);
    expect(container.read(kioskPageProvider), 1);
    expect(find.text(en.kioskPageClimateEnergy), findsWidgets);
    expect(find.byKey(const Key('kioskEnergy')), findsOneWidget);

    await tapKey(tester, 'kioskRenamePage');
    await settle(tester, 2);
    await tester.enterText(find.byKey(const Key('kioskPageName')), 'Klima');
    await tapKey(tester, 'kioskPageNameSave');
    await settle(tester, 3);
    expect(find.byKey(const ValueKey('kioskPageTitle-1')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('kioskPageTitle-1'))).data,
      'Klima',
    );
    await tapKey(tester, 'kioskLayoutDone');
    await settle(tester, 3);

    // Swipe back to the home page, then a dot to the second.
    await tester.fling(
      find.byKey(const Key('kioskPages')),
      const Offset(800, 0),
      2000,
    );
    await settle(tester, 6);
    expect(container.read(kioskPageProvider), 0);
    expect(find.byKey(const Key('kioskRooms')), findsOneWidget);
    await tapKey(tester, 'kioskPageDot-1');
    await settle(tester, 6);
    expect(container.read(kioskPageProvider), 1);

    // Untouched for the "return home" time: back to the home page.
    await tester.pump(container.read(kioskSettingsProvider).returnHomeAfter);
    await settle(tester, 6);
    expect(container.read(kioskPageProvider), 0);

    await tapKey(tester, 'kioskPageDot-1');
    await settle(tester, 6);
    await tapKey(tester, 'kioskEditLayout');
    await settle(tester, 3);
    await tapKey(tester, 'kioskDeletePage');
    await settle(tester, 6);
    expect(container.read(kioskSettingsProvider).pages, isEmpty);
    expect(find.byKey(const Key('kioskPages')), findsNothing);
    await unmount(tester);
  });

  test('a page with a time window becomes the default page', () {
    final evening = KioskPage.create(
      KioskPageTemplate.empty,
      'Veče',
    ).copyWith(schedule: (19 * 60, 23 * 60));
    final night = KioskPage.create(
      KioskPageTemplate.empty,
      'Noć',
    ).copyWith(schedule: (23 * 60, 6 * 60));
    final s = KioskSettings(pages: [evening, night]);
    expect(s.defaultPageAt(DateTime(2026, 10, 19, 12)), 0);
    expect(s.defaultPageAt(DateTime(2026, 10, 19, 20, 30)), 1);
    expect(s.defaultPageAt(DateTime(2026, 10, 19, 23, 30)), 2);
    expect(s.defaultPageAt(DateTime(2026, 10, 20, 2)), 2);
    expect(KioskSettings.fromJson(s.toJson()).pages[1].to, 6 * 60);
    expect(night.copyWith(clearSchedule: true).scheduled, isFalse);
  });

  testWidgets('the kiosk opens on the page for this time of day', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(1600, 1000));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    final now = DateTime.now();
    final m = now.hour * 60 + now.minute;
    await container
        .read(kioskSettingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            pages: [
              KioskPage.create(KioskPageTemplate.cameras, 'Sada').copyWith(
                schedule: ((m - 30) % (24 * 60), (m + 30) % (24 * 60)),
              ),
            ],
          ),
        );
    await goTo(tester, AppRoutes.settingsSection('kiosk'));
    await tapKey(tester, 'startKiosk');
    await settle(tester, 8);
    expect(container.read(kioskPageProvider), 1);
    expect(find.byKey(const ValueKey('kioskPageWindow-1')), findsOneWidget);
    await unmount(tester);
  });
}
