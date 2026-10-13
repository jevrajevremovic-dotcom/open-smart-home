import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../kiosk/application/kiosk_controller.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../devices/presentation/device_presentation.dart';
import '../application/weather_providers.dart';
import '../data/device_location.dart';
import '../domain/weather.dart';
import 'weather_labels.dart';

/// Weather at home (from Home Assistant) and, if the user enabled it, at the
/// device's location. Shown on the dashboard.
class WeatherSection extends ConsumerWidget {
  const WeatherSection({super.key, this.allowDeviceLocation = true});

  /// Hidden in kiosk mode (a wall panel does not move).
  final bool allowDeviceLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final home = ref.watch(homeWeatherProvider);
    final locator = ref.watch(deviceLocatorProvider);
    final deviceEnabled = ref.watch(deviceWeatherEnabledProvider);
    final offerDevice = allowDeviceLocation && locator.isSupported;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (home != null) ...[
          const SizedBox(height: 12),
          WeatherCard(
            report: home,
            title: l10n.weatherAtHome,
            onTap: () => context.push(
              AppRoutes.weatherFor(kiosk: ref.read(kioskActiveProvider)),
            ),
          ),
        ],
        if (offerDevice && deviceEnabled) const _DeviceWeather(),
        if (offerDevice && !deviceEnabled)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('enableDeviceWeather'),
              onPressed: () => enableDeviceWeather(context, ref),
              icon: const Icon(Icons.my_location_outlined),
              label: Text(l10n.weatherEnableDevice),
            ),
          ),
      ],
    );
  }
}

/// Explains what is sent before the OS permission prompt appears.
Future<void> enableDeviceWeather(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = context.l10n;
      return AlertDialog(
        icon: const Icon(Icons.my_location_outlined),
        title: Text(l10n.weatherEnableDevice),
        content: Text(l10n.weatherDeviceDisclosure),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirmDeviceWeather'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.weatherEnableDeviceConfirm),
          ),
        ],
      );
    },
  );
  if (ok == true) {
    await ref.read(deviceWeatherEnabledProvider.notifier).set(true);
  }
}

class _DeviceWeather extends ConsumerWidget {
  const _DeviceWeather();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(deviceWeatherProvider);
    Widget notice(Widget child) =>
        Padding(padding: const EdgeInsets.only(top: 12), child: child);
    return switch (state) {
      AsyncData(value: DeviceWeatherReady(:final report)) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: WeatherCard(
          report: report,
          title: l10n.weatherAtMyLocation,
          attribution: l10n.weatherMetAttribution,
        ),
      ),
      AsyncData(
        value: DeviceWeatherNoLocation(
          reason: LocationDenied(permanently: true),
        ),
      ) =>
        notice(
          Row(
            children: [
              Expanded(
                child: InlineNotice.warning(l10n.weatherLocationDeniedForever),
              ),
              TextButton(
                onPressed: () => ref.read(deviceLocatorProvider).openSettings(),
                child: Text(l10n.weatherOpenSettings),
              ),
            ],
          ),
        ),
      AsyncData(
        value: DeviceWeatherNoLocation(reason: LocationServicesOff()),
      ) =>
        notice(InlineNotice.warning(l10n.weatherLocationOff)),
      AsyncData(value: DeviceWeatherNoLocation()) => notice(
        InlineNotice.warning(l10n.weatherLocationDenied),
      ),
      AsyncError() => notice(
        InlineNotice.warning(l10n.weatherDeviceUnavailable),
      ),
      AsyncData(value: null) => const SizedBox.shrink(),
      _ => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    required this.report,
    required this.title,
    this.attribution,
    this.onTap,
  });

  final WeatherReport report;
  final String title;
  final String? attribution;

  /// Opens the full forecast.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final now = report.now;
    final temp = now.temperature == null
        ? '—'
        : formatNumber(locale, now.temperature!, unit: '°');
    final details = [
      if (now.humidity != null)
        '${l10n.summaryHumidity} ${formatNumber(locale, now.humidity!, unit: '%')}',
      if (now.windSpeed != null)
        '${l10n.weatherWind} ${formatNumber(locale, now.windSpeed!, unit: now.windSpeedUnit)}',
    ].join(' · ');

    return Card.outlined(
      key: ValueKey('weather-${report.source.name}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Semantics(
                label:
                    '$title: ${weatherConditionLabel(l10n, now.condition)}, $temp',
                excludeSemantics: true,
                child: Row(
                  children: [
                    Icon(
                      weatherIcon(now.condition),
                      size: 44,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(temp, style: theme.textTheme.displaySmall),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weatherConditionLabel(l10n, now.condition),
                            style: theme.textTheme.titleMedium,
                          ),
                          if (details.isNotEmpty)
                            Text(details, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (report.daily.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final day in report.daily.take(5))
                      Expanded(
                        child: Semantics(
                          label:
                              '${DateFormat.EEEE(locale).format(day.date)}: ${weatherConditionLabel(l10n, day.condition)}, '
                              '${day.high == null ? '' : formatNumber(locale, day.high!, unit: '°')} / '
                              '${day.low == null ? '' : formatNumber(locale, day.low!, unit: '°')}',
                          excludeSemantics: true,
                          child: Column(
                            children: [
                              Text(
                                DateFormat.E(locale).format(day.date),
                                style: theme.textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Icon(weatherIcon(day.condition), size: 22),
                              const SizedBox(height: 4),
                              // High above low: never truncated in narrow panes.
                              Text(
                                day.high == null
                                    ? '—'
                                    : formatNumber(
                                        locale,
                                        day.high!,
                                        unit: '°',
                                      ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                day.low == null
                                    ? ''
                                    : formatNumber(locale, day.low!, unit: '°'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (attribution != null) ...[
                const SizedBox(height: 8),
                Text(
                  attribution!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
