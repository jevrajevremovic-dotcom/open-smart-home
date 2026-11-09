import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/energy/application/electricity_prices.dart';
import 'package:open_smart_home/integrations/home_assistant/models/ha_models.dart';

import '../widgets/app_widget_test.dart' show goTo, pumpApp, settle, unmount;

void main() {
  final day = DateTime(2026, 11, 9);
  DateTime h(int hour) => day.add(Duration(hours: hour));

  test('Nord Pool, ENTSO-e and EPEX Spot price lists', () {
    final nordpool = HaEntityState(
      entityId: 'sensor.nordpool',
      state: '0.1',
      attributes: {
        'raw_today': [
          for (var i = 0; i < 3; i++)
            {
              'start': h(i).toIso8601String(),
              'end': h(i + 1).toIso8601String(),
              'value': 0.1 * (i + 1),
            },
        ],
      },
    );
    final slots = parsePriceSlots(nordpool);
    expect(slots.length, 3);
    expect(slots[2].price, closeTo(0.3, 1e-9));
    expect(slots[2].end, h(3));

    final entsoe = HaEntityState(
      entityId: 'sensor.entsoe',
      state: '0.1',
      attributes: {
        'prices_today': [
          {'time': h(0).toIso8601String(), 'price': 0.2},
          {'time': h(1).toIso8601String(), 'price': '0.1'},
        ],
      },
    );
    final e = parsePriceSlots(entsoe);
    expect([for (final s in e) s.price], [0.2, 0.1]);
    expect(e.first.end, h(1), reason: 'ends where the next one starts');
    expect(e.last.end, h(2), reason: 'last one: an hour');

    final epex = HaEntityState(
      entityId: 'sensor.epex',
      state: '0.1',
      attributes: {
        'data': [
          {
            'start_time': h(5).toIso8601String(),
            'end_time': h(5).add(const Duration(minutes: 15)).toIso8601String(),
            'price_per_kwh': 0.05,
          },
        ],
      },
    );
    expect(parsePriceSlots(epex).single.length, const Duration(minutes: 15));
    expect(
      parsePriceSlots(
        const HaEntityState(entityId: 'sensor.t', state: '1', attributes: {}),
      ),
      isEmpty,
    );
  });

  test('cheapest window: contiguous, from now on, averaged', () {
    final prices = [5.0, 1.0, 3.0, 0.5, 9.0, 0.1];
    final slots = [
      for (final (i, p) in prices.indexed) PriceSlot(h(i), h(i + 1), p),
    ];
    final two = cheapestWindow(slots, const Duration(hours: 2), h(0));
    expect(two!.$1, h(2));
    expect(two.$3, closeTo(1.75, 1e-9));
    final one = cheapestWindow(slots, const Duration(hours: 1), h(0));
    expect(one!.$1, h(5));
    expect(
      cheapestWindow(
        slots,
        const Duration(hours: 1),
        h(5).add(const Duration(minutes: 10)),
      )!.$1,
      h(5),
      reason: 'the hour in progress still counts',
    );
    expect(cheapestWindow(slots, const Duration(hours: 7), h(0)), isNull);
    // A gap in the data breaks a window.
    final gappy = [PriceSlot(h(0), h(1), 1), PriceSlot(h(2), h(3), 1)];
    expect(cheapestWindow(gappy, const Duration(hours: 2), h(0)), isNull);
  });

  testWidgets('energy screen shows prices and the cheapest time', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true, size: const Size(900, 1800));
    await settle(tester, 10);
    await goTo(tester, AppRoutes.energy);
    await settle(tester, 6);
    final section = find.byKey(const Key('priceSection'));
    await tester.scrollUntilVisible(
      section,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(section, findsOneWidget);
    expect(find.byKey(const Key('priceCheapest')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('priceHours-3')));
    await settle(tester, 2);
    expect(find.byKey(const Key('priceCheapest')), findsOneWidget);
    await unmount(tester);
  });
}
