import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/devices/application/device_providers.dart';
import 'package:open_smart_home/features/devices/domain/device_kind.dart';
import 'package:open_smart_home/features/restricted/application/restricted_mode.dart';

import '../widgets/app_widget_test.dart'
    show en, goTo, pumpApp, settle, tapKey, unmount;

void main() {
  test('hidden kinds follow the options; off hides nothing', () {
    const on = RestrictedSettings(enabled: true, hideCameras: false);
    expect(on.hiddenKinds, contains(DeviceKind.lock));
    expect(on.hiddenKinds, isNot(contains(DeviceKind.camera)));
    expect(const RestrictedSettings().hiddenKinds, isEmpty);
    expect(
      RestrictedSettings.fromJson({'enabled': true}).enabled,
      isFalse,
      reason: 'never on without a PIN',
    );
  });

  test('router keeps children out of adding devices', () {
    expect(
      resolveRedirect(
        location: AppRoutes.addDevice,
        sessionLoading: false,
        signedIn: true,
        serverChosen: true,
        restricted: true,
      ),
      AppRoutes.home,
    );
  });

  testWidgets('turn on with a PIN, devices hidden, settings closed, PIN off', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(800, 1600));
    await settle(tester, 10);
    await goTo(tester, AppRoutes.settingsSection('security'));
    await tapKey(tester, 'restrictedSettings');
    await settle(tester, 4);
    await tapKey(tester, 'restrictedEnable');
    await settle(tester, 2);
    await tester.enterText(find.byKey(const Key('pinField')), '2468');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, 4);
    await tester.enterText(find.byKey(const Key('pinField')), '2468');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, 6);

    // Settings are closed; Assist is gone; the lock is hidden.
    await goTo(tester, AppRoutes.settingsSection('security'));
    await settle(tester, 2);
    expect(find.byKey(const Key('restrictedActive')), findsOneWidget);
    expect(find.byKey(const Key('signOutButton')), findsNothing);
    await goTo(tester, AppRoutes.home);
    await settle(tester, 2);
    expect(find.byKey(const Key('openAssist')), findsNothing);
    await goTo(tester, AppRoutes.device('lock.front_door'));
    await settle(tester, 2);
    expect(find.text(en.restrictedHidden), findsOneWidget);
    await goTo(tester, AppRoutes.addDevice);
    await settle(tester, 2);
    expect(find.text(en.addDeviceTitle), findsNothing);

    await goTo(tester, AppRoutes.settingsSection('security'));
    await settle(tester, 2);
    await tapKey(tester, 'restrictedDisable');
    await settle(tester, 2);
    await tester.enterText(find.byKey(const Key('pinField')), '1111');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, 4);
    expect(find.text(en.kioskWrongPin), findsOneWidget);
    await tester.enterText(find.byKey(const Key('pinField')), '2468');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, 6);
    // Settings are open again.
    expect(find.byKey(const Key('restrictedSettings')), findsOneWidget);
    await unmount(tester);
  });

  test('a guest sees only the chosen rooms; settings survive storage', () {
    final s = RestrictedSettings.fromJson({
      'enabled': true,
      'pinHash': 'h',
      'pinSalt': 's',
      'rooms': ['kitchen'],
      'until': '2026-11-09T20:00:00.000',
    });
    expect(s.rooms, ['kitchen']);
    expect(s.until, DateTime(2026, 11, 9, 20));
    expect(RestrictedSettings.fromJson(s.toJson()).rooms, ['kitchen']);
    expect(const RestrictedSettings().toJson().containsKey('until'), isFalse);
  });

  testWidgets('a guest for two hours in one room; then locked until the PIN', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(800, 1600));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    await goTo(tester, AppRoutes.settingsSection('security'));
    await tapKey(tester, 'restrictedSettings');
    await settle(tester, 4);
    await tapKey(tester, 'guestRoom-living_room');
    await tapKey(tester, 'guestTime-hours2');
    await settle(tester);
    await tester.ensureVisible(find.byKey(const Key('restrictedEnable')));
    await tapKey(tester, 'restrictedEnable');
    await settle(tester, 2);
    for (var i = 0; i < 2; i++) {
      await tester.enterText(find.byKey(const Key('pinField')), '2468');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester, 4);
    }
    final s = container.read(restrictedModeProvider);
    expect(s.enabled, isTrue);
    expect(s.rooms, ['living_room']);
    final left = s.until!.difference(DateTime.now());
    expect(left.inMinutes, inInclusiveRange(118, 120));
    final devices = container.read(homeSnapshotProvider).devices;
    final visible = container.read(visibleDeviceIdsProvider);
    expect(visible, isNotEmpty);
    expect(visible.every((id) => devices[id]!.roomId == 'living_room'), isTrue);
    await goTo(tester, AppRoutes.settingsSection('security'));
    await settle(tester, 2);
    expect(find.byKey(const Key('restrictedUntil')), findsOneWidget);

    // Time is up.
    await container
        .read(restrictedModeProvider.notifier)
        .setOptions(until: DateTime.now().subtract(const Duration(minutes: 1)));
    await settle(tester, 2);
    expect(find.byKey(const Key('guestExpired')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('guestExpiredPin')), '1111');
    await tapKey(tester, 'guestExpiredUnlock');
    await settle(tester, 4);
    expect(find.text(en.kioskWrongPin), findsOneWidget);
    await tester.enterText(find.byKey(const Key('guestExpiredPin')), '2468');
    await tapKey(tester, 'guestExpiredUnlock');
    await settle(tester, 6);
    expect(find.byKey(const Key('guestExpired')), findsNothing);
    expect(container.read(restrictedModeProvider).enabled, isFalse);
    await unmount(tester);
  });
}
