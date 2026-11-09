import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n.dart';
import '../application/electricity_prices.dart';
import 'energy_chart.dart';

/// Today's and tomorrow's electricity prices from a Home Assistant sensor
/// (Nord Pool, ENTSO-e, EPEX Spot) and the cheapest time to run the
/// washing machine or charge the car. Hidden when there is no such sensor.
class ElectricityPriceSection extends ConsumerStatefulWidget {
  const ElectricityPriceSection({super.key});

  @override
  ConsumerState<ElectricityPriceSection> createState() =>
      _ElectricityPriceSectionState();
}

class _ElectricityPriceSectionState
    extends ConsumerState<ElectricityPriceSection> {
  int _hours = 2;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final prices = ref.watch(electricityPricesProvider).value;
    if (prices == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final hm = DateFormat.Hm(locale);
    // Shown per hour (15-minute prices averaged), from this hour on.
    final hourStart = DateTime(now.year, now.month, now.day, now.hour);
    final byHour = <DateTime, List<double>>{};
    for (final s in prices.slots) {
      final h = DateTime(
        s.start.year,
        s.start.month,
        s.start.day,
        s.start.hour,
      );
      if (h.isBefore(hourStart)) continue;
      byHour.putIfAbsent(h, () => []).add(s.price);
    }
    final hours = byHour.keys.toList()..sort();
    final values = [
      for (final h in hours)
        byHour[h]!.reduce((a, b) => a + b) / byHour[h]!.length,
    ];
    final current = prices.at(now);
    final best = cheapestWindow(prices.slots, Duration(hours: _hours), now);
    final selected = _selected != null && _selected! < hours.length
        ? _selected
        : null;
    final caption = selected != null
        ? '${DateFormat.E(locale).add_Hm().format(hours[selected])} · '
              '${formatPrice(locale, values[selected], prices.unit)}'
        : current == null
        ? ''
        : l10n.priceNow(formatPrice(locale, current.price, prices.unit));
    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);
    return Card.outlined(
      key: const Key('priceSection'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.priceTitle, style: theme.textTheme.titleMedium),
            Text(
              l10n.priceSource(prices.name),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(caption, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            if (hours.isNotEmpty) ...[
              Semantics(
                label: '${l10n.priceTitle}. $caption',
                child: LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      final i =
                          (d.localPosition.dx /
                                  constraints.maxWidth *
                                  hours.length)
                              .floor()
                              .clamp(0, hours.length - 1);
                      setState(() => _selected = _selected == i ? null : i);
                    },
                    child: SizedBox(
                      height: 140,
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, 140),
                        painter: EnergyBarsPainter(
                          // The cheapest window, on a band behind the bars.
                          shaded: [
                            for (final h in hours)
                              best != null &&
                                  !h.isBefore(
                                    DateTime(
                                      best.$1.year,
                                      best.$1.month,
                                      best.$1.day,
                                      best.$1.hour,
                                    ),
                                  ) &&
                                  h.isBefore(best.$2),
                          ],
                          shade: theme.colorScheme.secondaryContainer,
                          values: values,
                          maxValue: maxValue,
                          selected: selected,
                          bar: theme.colorScheme.primary,
                          axis: theme.colorScheme.outlineVariant,
                          surface: theme.colorScheme.surface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              EnergyAxisLabels(labels: [for (final h in hours) hm.format(h)]),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.priceCheapestFor),
                for (final h in const [1, 2, 3, 4])
                  ChoiceChip(
                    key: ValueKey('priceHours-$h'),
                    label: Text(l10n.priceHours(h)),
                    selected: _hours == h,
                    onSelected: (_) => setState(() => _hours = h),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              best == null
                  ? l10n.priceNoWindow
                  : cheapestLabel(l10n, best, now, prices.unit),
              key: const Key('priceCheapest'),
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// A price with three decimals below 1 (0,125 €/kWh), else two.
String formatPrice(String locale, double v, String? unit) {
  final digits = v.abs() < 1 ? 3 : 2;
  final text = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: digits,
  ).format(v);
  return unit == null ? text : '$text $unit';
}

/// "Cheapest: tomorrow 02:00–05:00, on average 0,081 €/kWh".
String cheapestLabel(
  AppLocalizations l10n,
  (DateTime, DateTime, double) best,
  DateTime now,
  String? unit,
) {
  final hm = DateFormat.Hm(l10n.localeName);
  final (start, end, price) = best;
  return l10n.priceCheapest(
    start.isAfter(now)
        ? '${start.day != now.day ? '${l10n.priceTomorrow} ' : ''}'
              '${hm.format(start)}'
        : l10n.priceFromNow,
    hm.format(end),
    formatPrice(l10n.localeName, price, unit),
  );
}
