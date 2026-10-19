import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/energy/application/energy_providers.dart';
import 'package:open_smart_home/features/energy/data/tariff.dart';
import 'package:open_smart_home/features/kiosk/application/kiosk_controller.dart';
import 'package:open_smart_home/features/kiosk/data/kiosk_layout.dart';

import '../widgets/app_widget_test.dart'
    show en, goTo, pumpApp, settle, unmount;

void main() {
  testWidgets('energy as a kiosk panel: live power, today, rate', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(1600, 1000));
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    final now = DateTime.now();
    // Lower rate starting in an hour, so the text is predictable.
    final from = (now.hour + 1) % 24;
    await container
        .read(tariffProvider.notifier)
        .save(
          Tariff(
            importPrice: 15,
            low: LowTariff(fromHour: from, toHour: (from + 6) % 24, price: 5),
          ),
        );
    await container
        .read(kioskSettingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            layout: const KioskLayout([
              KioskPanel(id: 'e', type: KioskPanelType.energy, span: 6),
              KioskPanel(id: 'r', type: KioskPanelType.rooms, span: 6),
            ]),
          ),
        );
    container.read(kioskActiveProvider.notifier).enter();
    await goTo(tester, AppRoutes.kiosk);
    await settle(tester, 10);

    expect(find.byKey(const Key('kioskEnergy')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('kioskEnergyPower'))).data,
      '742 W',
    );
    expect(find.textContaining('Today '), findsOneWidget);
    expect(find.textContaining('Higher rate · lower in '), findsOneWidget);
    expect(en.energyTitle, isNotEmpty);
    await unmount(tester);
  });
}
