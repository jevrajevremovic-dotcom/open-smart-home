import '../../devices/domain/smart_home_device.dart';
import '../domain/weather.dart';

/// Current weather from a Home Assistant weather entity.
WeatherReport weatherFromEntity(
  SmartHomeDevice d, {
  List<DailyForecast> daily = const [],
}) => WeatherReport(
  source: WeatherSource.home,
  title: d.name,
  updatedAt: d.metadata.lastUpdated,
  daily: daily,
  now: WeatherNow(
    condition: WeatherCondition.fromHomeAssistant(d.state.raw),
    temperature: d.state.currentTemperature,
    temperatureUnit: d.state.unit ?? '°C',
    humidity: d.state.currentHumidity,
    windSpeed: d.state.windSpeed,
    windSpeedUnit: d.state.windSpeedUnit,
  ),
);

/// Parses the `weather.get_forecasts` service response:
/// `{"weather.x": {"forecast": [{datetime, condition, temperature, templow, precipitation}]}}`.
List<DailyForecast> parseHaForecast(Object? response, String entityId) {
  if (response is! Map) return const [];
  final entry = response[entityId];
  final list = entry is Map ? entry['forecast'] : null;
  if (list is! List) return const [];
  double? num_(Object? v) => v is num ? v.toDouble() : null;
  return [
    for (final f in list)
      if (f is Map &&
          f['datetime'] is String &&
          DateTime.tryParse(f['datetime'] as String) != null)
        DailyForecast(
          date: DateTime.parse(f['datetime'] as String).toLocal(),
          condition: WeatherCondition.fromHomeAssistant(
            f['condition'] as String?,
          ),
          high: num_(f['temperature']),
          low: num_(f['templow']),
          precipitation: num_(f['precipitation']),
        ),
  ];
}
