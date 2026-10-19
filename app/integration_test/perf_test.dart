// Smoothness on a real device: frame build/raster times while scrolling the
// home screen, swiping kiosk pages and opening kiosk windows. Run in profile
// mode with test_driver/perf_driver.dart.
//
// WARNING: only on an emulator or a spare device. `flutter drive`
// uninstalls the app when it ends, which deletes its data (login,
// settings) on a real wall panel.
//
// Everything stays in memory (demo server, preferences, credentials): the
// app data already on the device is not touched.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/kiosk/application/kiosk_controller.dart';
import 'package:open_smart_home/features/kiosk/data/kiosk_layout.dart';

import '../test/helpers.dart';

const _profile =
    '{"url":"http://homeassistant.local:8123","pinnedCertificateSha256":null,"insecureConnectionAcknowledged":false}';

Future<void> wait(WidgetTester tester, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('performance', (tester) async {
    final credentials = InMemoryCredentialStore();
    credentials.values['http://homeassistant.local:8123'] = 'token';
    await tester.pumpWidget(
      ProviderScope(
        overrides: await testOverrides(
          credentials: credentials,
          preferences: {'connection.activeServerProfile': _profile},
          speech: FakeSpeechOutput(supported: false),
        ),
        retry: (_, _) => null,
        child: const SmartHomeApp(),
      ),
    );
    await wait(tester, 4000);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );

    await binding.watchPerformance(() async {
      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 3; i++) {
        await tester.fling(list, const Offset(0, -900), 2500);
        await wait(tester, 900);
        await tester.fling(list, const Offset(0, 900), 2500);
        await wait(tester, 900);
      }
    }, reportKey: 'home_scroll');

    await container
        .read(kioskSettingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            pages: [
              KioskPage.create(KioskPageTemplate.climateEnergy, 'Klima'),
              KioskPage.create(KioskPageTemplate.cameras, 'Kamere'),
            ],
          ),
        );
    container.read(kioskActiveProvider.notifier).enter();
    container.read(routerProvider).go(AppRoutes.kiosk);
    await wait(tester, 4000);

    await binding.watchPerformance(() async {
      final pages = find.byKey(const Key('kioskPages'));
      for (var i = 0; i < 2; i++) {
        await tester.fling(pages, const Offset(-900, 0), 2500);
        await wait(tester, 1200);
        await tester.fling(pages, const Offset(-900, 0), 2500);
        await wait(tester, 1200);
        await tester.fling(pages, const Offset(900, 0), 2500);
        await wait(tester, 1200);
        await tester.fling(pages, const Offset(900, 0), 2500);
        await wait(tester, 1200);
      }
    }, reportKey: 'kiosk_pages');

    await binding.watchPerformance(() async {
      for (final key in ['kioskTimer', 'kioskLeaving', 'kioskAlarm']) {
        await tester.tap(find.byKey(Key(key)));
        await wait(tester, 1200);
        await tester.tapAt(const Offset(8, 8)); // outside: closes
        await wait(tester, 1000);
      }
    }, reportKey: 'kiosk_dialogs');

    // Idle kiosk: what it costs to just sit there for 10 s.
    await binding.watchPerformance(() async {
      await wait(tester, 10000);
    }, reportKey: 'kiosk_idle');
  });
}
