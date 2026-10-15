import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/ha_notify/ha_push.dart';
import 'package:open_smart_home/integrations/home_assistant/home_assistant_providers.dart';

import '../helpers.dart' show FakeAlertNotifier;
import '../widgets/app_widget_test.dart'
    show en, goTo, pumpApp, settle, tapKey, unmount;

void main() {
  test('notify service name follows Home Assistant slugs', () {
    expect(haSlug('Zidni tablet – Hodnik'), 'zidni_tablet_hodnik');
    expect(haSlug('Đorđev telefon'), 'dordev_telefon');
    expect(
      const MobileAppRegistration(
        webhookId: 'x',
        deviceName: 'Kuhinja Tablet',
      ).notifyService,
      'notify.mobile_app_kuhinja_tablet',
    );
  });

  testWidgets('register, receive and confirm a message, then sign out', (
    tester,
  ) async {
    final notifier = FakeAlertNotifier();
    final credentials = await pumpApp(
      tester,
      signedIn: true,
      size: const Size(800, 1600),
      alerts: notifier,
    );
    await settle(tester, 10);
    final server = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    ).read(mockHomeAssistantServerProvider);

    await goTo(tester, AppRoutes.settings);
    await tapKey(tester, 'haPushTile');
    await settle(tester, 3);
    await tester.enterText(find.byKey(const Key('haPushName')), 'Zidni tablet');
    await tester.tap(find.byKey(const Key('haPushRegister')));
    await settle(tester, 8);

    expect(server.mobileApps, hasLength(1));
    final body = server.mobileApps.values.single;
    expect(body['device_name'], 'Zidni tablet');
    expect((body['app_data']! as Map)['push_websocket_channel'], isTrue);
    expect(
      find.text(en.haPushReady('notify.mobile_app_zidni_tablet')),
      findsOneWidget,
    );
    // The webhook id is a secret: stored with the credentials.
    expect(
      credentials.values.keys,
      contains('mobile_app::http://homeassistant.local:8123'),
    );

    final webhook = server.mobileApps.keys.single;
    server.sendPush(webhook, title: 'Veš', message: 'Pranje je završeno.');
    await settle(tester, 4);
    expect(notifier.messages, [('Veš', 'Pranje je završeno.')]);
    expect(server.confirmedPushes, hasLength(1), reason: 'confirmed');

    // A dropped connection resubscribes when it is back.
    await server.dropAllConnections();
    await settle(tester, 40);
    server.sendPush(webhook, message: 'Ponovo tu');
    await settle(tester, 4);
    expect(notifier.messages.last, (null, 'Ponovo tu'));

    await goTo(tester, AppRoutes.settings);
    await tapKey(tester, 'signOutButton');
    await settle(tester, 3);
    await tapKey(tester, 'confirmDialogAction');
    await settle(tester, 5);
    expect(credentials.values, isEmpty, reason: 'webhook id removed too');
    await unmount(tester);
  });
}
