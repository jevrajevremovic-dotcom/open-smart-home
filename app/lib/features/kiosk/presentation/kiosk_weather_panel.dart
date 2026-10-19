part of 'kiosk_panels.dart';

/// Weather at home: current conditions and the next four days.
class KioskWeatherPanel extends ConsumerWidget {
  const KioskWeatherPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(homeWeatherProvider);
    final l10n = context.l10n;
    if (report == null) {
      return GlassPanel(
        key: const Key('kioskWeatherMissing'),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: GlassColors.muted,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.kioskWeatherMissing,
                textAlign: TextAlign.center,
                style: const TextStyle(color: GlassColors.muted),
              ),
            ],
          ),
        ),
      );
    }
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final now = report.now;
    String t(double? v) => v == null ? '—' : formatNumber(locale, v, unit: '°');
    final today = report.daily.isEmpty ? null : report.daily.first;
    final next = report.daily.skip(1).take(5).toList();
    // Every second hour so six cells cover half a day.
    final hours = [
      for (final (i, h) in report.hourly.skip(1).indexed)
        if (i.isEven) h,
    ].take(6).toList();

    Widget cell(String top, IconData icon, String main, [String? sub]) =>
        SizedBox(
          width: 66,
          child: Column(
            children: [
              Text(
                top,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: GlassColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Icon(icon, color: GlassColors.text, size: 28),
              const SizedBox(height: 6),
              Text(
                main,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: GlassColors.text,
                ),
              ),
              if (sub != null)
                Text(
                  sub,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: GlassColors.faint,
                  ),
                ),
            ],
          ),
        );

    return GestureDetector(
      key: const Key('kioskWeather'),
      onTap: () => context.push(AppRoutes.weatherFor(kiosk: true)),
      child: GlassPanel(
        child: Semantics(
          button: true,
          label:
              '${l10n.weatherForecastTitle}. ${weatherConditionLabel(l10n, now.condition)}, '
              '${t(now.temperature)}',
          child: LayoutBuilder(
            builder: (context, c) {
              // Low and wide cells: now, hours and days side by side, so
              // nothing has to shrink.
              final wide = c.maxWidth > c.maxHeight * 2.2 && next.isNotEmpty;
              final parts = <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      weatherIcon(now.condition),
                      size: 72,
                      color: const Color(0xFF8CC8FF),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      t(now.temperature),
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: GlassColors.text,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weatherConditionLabel(l10n, now.condition),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: GlassColors.text,
                          ),
                        ),
                        if (today != null)
                          Text(
                            '↑ ${t(today.high)}   ↓ ${t(today.low)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: GlassColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (hours.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final h in hours)
                        cell(
                          DateFormat.Hm(locale).format(h.time),
                          weatherIcon(h.condition),
                          t(h.temperature),
                        ),
                    ],
                  ),
                ],
                if (report.source == WeatherSource.homeLocation) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.weatherMetAttribution,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: GlassColors.faint,
                    ),
                  ),
                ],
                if (next.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: 66.0 * math.max(hours.length, next.length),
                    height: 1,
                    color: GlassColors.border,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final day in next)
                        cell(
                          DateFormat.E(locale).format(day.date),
                          weatherIcon(day.condition),
                          t(day.high),
                          t(day.low),
                        ),
                    ],
                  ),
                ],
              ];
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: ExcludeSemantics(
                  child: wide
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                parts.first,
                                ...parts.whereType<Text>(),
                              ],
                            ),
                            for (final row
                                in parts.skip(1).whereType<Row>()) ...[
                              Container(
                                width: 1,
                                height: 96,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                color: GlassColors.border,
                              ),
                              row,
                            ],
                          ],
                        )
                      : Column(mainAxisSize: MainAxisSize.min, children: parts),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
