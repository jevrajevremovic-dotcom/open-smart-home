import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n.dart';
import '../../dashboard/application/home_summaries.dart';
import '../../devices/application/device_providers.dart';
import '../../energy/application/energy_providers.dart';
import '../../energy/data/energy_repository.dart';
import '../../energy/presentation/energy_format.dart';
import 'glass.dart';
import 'kiosk_panels.dart' show kioskNowProvider;

/// Today's energy for the wall, independent of the range picked on the
/// energy screen; refreshed every 5 minutes.
final kioskEnergyTodayProvider = FutureProvider.autoDispose<EnergyReport?>((
  ref,
) async {
  final timer = Timer(const Duration(minutes: 5), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  final prefs = await ref.watch(energyPrefsProvider.future);
  final repository = ref.watch(energyRepositoryProvider);
  if (prefs == null || repository == null) return null;
  return repository.loadReport(
    prefs,
    EnergyRange.today,
    now: DateTime.now(),
    lowHours: ref.watch(tariffProvider.select((t) => t?.low?.hours)),
  );
});

/// Live power as a big gauge, today's consumption (and cost, with a
/// tariff), the current rate with the time to the next change, and solar
/// when there is any.
class KioskEnergyPanel extends ConsumerWidget {
  const KioskEnergyPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    final powerId = ref.watch(
      dashboardSummaryProvider.select((s) => s.powerDeviceId),
    );
    final power = powerId == null
        ? null
        : ref.watch(deviceProvider(powerId))?.state.numericValue;
    final report = ref.watch(kioskEnergyTodayProvider).value;
    final tariff = ref.watch(tariffProvider);
    final now = ref.watch(kioskNowProvider);
    final low = tariff?.low;
    final cost = tariff?.estimate(
      gridImport: report?.gridImport,
      gridExport: report?.gridExport,
      gridImportLow: report?.gridImportLow,
    );

    String? rate;
    if (low != null) {
      final lowNow = low.containsHour(now.hour);
      final left = low.nextChange(now).difference(now);
      final span = left.inHours > 0
          ? '${left.inHours} h ${left.inMinutes.remainder(60)} min'
          : '${left.inMinutes} min';
      rate = lowNow
          ? l10n.kioskEnergyLowFor(span)
          : l10n.kioskEnergyLowIn(span);
    }

    final lines = <(IconData, String)>[
      if (report?.consumption case final kwh?)
        (Icons.today_outlined, l10n.kioskEnergyToday(formatKwh(locale, kwh))),
      if (cost != null && tariff != null)
        (Icons.payments_outlined, formatMoney(locale, cost, tariff.currency)),
      if (report?.solar case final solar? when solar > 0)
        (
          Icons.solar_power_outlined,
          l10n.kioskEnergySolar(formatKwh(locale, solar)),
        ),
      if (rate != null)
        (
          low!.containsHour(now.hour)
              ? Icons.nights_stay
              : Icons.wb_sunny_outlined,
          rate,
        ),
    ];

    return GlassPanel(
      key: const Key('kioskEnergy'),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, c) {
          final gauge = SizedBox.square(
            dimension: math.min(220, math.min(c.maxWidth, c.maxHeight) - 8),
            child: _PowerGauge(watts: power, locale: locale),
          );
          final details = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.energyTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: GlassColors.text,
                ),
              ),
              const SizedBox(height: 12),
              for (final (icon, text) in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: GlassColors.muted),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          text,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: GlassColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
          return c.maxWidth > 480
              ? Row(
                  children: [
                    gauge,
                    const SizedBox(width: 24),
                    Expanded(child: details),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [gauge, const SizedBox(height: 12), details],
                  ),
                );
        },
      ),
    );
  }
}

/// Arc from 0 to a round maximum (3, 5, 10, 20 kW…): green, amber, red.
class _PowerGauge extends StatelessWidget {
  const _PowerGauge({required this.watts, required this.locale});

  final double? watts;
  final String locale;

  static double scaleFor(double w) {
    for (final kw in const [3, 5, 10, 20, 50]) {
      if (w <= kw * 1000) return kw * 1000.0;
    }
    return (w / 1000).ceilToDouble() * 1000;
  }

  @override
  Widget build(BuildContext context) {
    final w = watts;
    final theme = Theme.of(context);
    final max = scaleFor(w ?? 0);
    final f = w == null ? 0.0 : (w / max).clamp(0.0, 1.0);
    final color = w == null
        ? GlassColors.faint
        : w < 1000
        ? const Color(0xFF66BB6A)
        : w < 3000
        ? const Color(0xFFFFB74D)
        : const Color(0xFFEF5350);
    final value = w == null
        ? '—'
        : w >= 1000
        ? '${NumberFormat('0.0', locale).format(w / 1000)} kW'
        : '${w.round()} W';
    return CustomPaint(
      painter: _GaugePainter(fraction: f, color: color),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              value,
              key: const Key('kioskEnergyPower'),
              style: theme.textTheme.displaySmall?.copyWith(
                color: GlassColors.text,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;
    final stroke = size.shortestSide * 0.09;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, start, sweep, false, track);
    if (fraction > 0) {
      canvas.drawArc(arc, start, sweep * fraction, false, track..color = color);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction || old.color != color;
}
