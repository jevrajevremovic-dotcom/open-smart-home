import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/features/weather/application/weather_providers.dart';
import 'package:open_smart_home/features/weather/data/device_location.dart';
import 'package:open_smart_home/features/weather/data/ha_weather.dart';
import 'package:open_smart_home/features/weather/data/met_norway_client.dart';
import 'package:open_smart_home/features/weather/domain/weather.dart';
import 'package:open_smart_home/integrations/home_assistant/mappers/ha_device_mapper.dart';
import 'package:open_smart_home/integrations/home_assistant/models/ha_models.dart';
import 'package:open_smart_home/integrations/home_assistant/models/ha_registry.dart';

import '../helpers.dart';
import '../integrations/home_assistant_api_test.dart' show FakeAdapter;
import '../widgets/app_widget_test.dart'
    show en, goTo, pumpApp, settle, tapKey, unmount;

Map<String, Object?> metEntry(
  DateTime t, {
  double temp = 10,
  String symbol = 'cloudy',
  double rain = 0,
  bool hourly = true,
}) => {
  'time': t.toUtc().toIso8601String(),
  'data': {
    'instant': {
      'details': {
        'air_temperature': temp,
        'relative_humidity': 70.0,
        'wind_speed': 5.0,
      },
    },
    if (hourly)
      'next_1_hours': {
        'summary': {'symbol_code': symbol},
        'details': {'precipitation_amount': rain},
      },
    'next_6_hours': {
      'summary': {'symbol_code': symbol},
      'details': {'precipitation_amount': rain * 6},
    },
  },
};

class DeniedLocator implements DeviceLocator {
  @override
  bool get isSupported => true;
  @override
  Future<LocationResult> approximateLocation() async =>
      const LocationDenied(permanently: true);
  @override
  Future<void> openSettings() async {}
}

void main() {
  group('conditions', () {
    test('Home Assistant values', () {
      expect(
        WeatherCondition.fromHomeAssistant('partlycloudy'),
        WeatherCondition.partlyCloudy,
      );
      expect(
        WeatherCondition.fromHomeAssistant('lightning-rainy'),
        WeatherCondition.thunderstorm,
      );
      expect(
        WeatherCondition.fromHomeAssistant('???'),
        WeatherCondition.unknown,
      );
    });

    test('MET Norway symbol codes', () {
      expect(
        WeatherCondition.fromMetSymbol('clearsky_day'),
        WeatherCondition.clearDay,
      );
      expect(
        WeatherCondition.fromMetSymbol('clearsky_night'),
        WeatherCondition.clearNight,
      );
      expect(
        WeatherCondition.fromMetSymbol('fair_day'),
        WeatherCondition.partlyCloudy,
      );
      expect(
        WeatherCondition.fromMetSymbol('heavyrainandthunder'),
        WeatherCondition.thunderstorm,
      );
      expect(
        WeatherCondition.fromMetSymbol('lightsleetshowers_day'),
        WeatherCondition.sleet,
      );
      expect(WeatherCondition.fromMetSymbol('snow'), WeatherCondition.snow);
      expect(
        WeatherCondition.fromMetSymbol('lightrain'),
        WeatherCondition.rain,
      );
    });
  });

  test('HA weather entity and get_forecasts response', () {
    final device = const HaDeviceMapper().map(
      const HaEntityState(
        entityId: 'weather.forecast_home',
        state: 'rainy',
        attributes: {
          'temperature': 12.5,
          'humidity': 80,
          'wind_speed': 20,
          'wind_speed_unit': 'km/h',
          'friendly_name': 'Forecast Home',
        },
      ),
      HaRegistries.empty,
    );
    final daily = parseHaForecast({
      'weather.forecast_home': {
        'forecast': [
          {
            'datetime': '2026-10-14T10:00:00+00:00',
            'condition': 'sunny',
            'temperature': 20,
            'templow': 9,
          },
          {'datetime': 'bad'},
        ],
      },
    }, 'weather.forecast_home');
    final report = weatherFromEntity(device, daily: daily);
    expect(report.now.condition, WeatherCondition.rain);
    expect(
      (report.now.temperature, report.now.humidity, report.now.windSpeed),
      (12.5, 80.0, 20.0),
    );
    expect(daily.single.high, 20);
    expect(parseHaForecast('garbage', 'x'), isEmpty);
  });

  group('MET Norway', () {
    final now = DateTime(2026, 10, 13, 9);

    test('parses current conditions and daily min/max/rain', () {
      final r = parseMetForecast({
        'properties': {
          'timeseries': [
            metEntry(
              DateTime(2026, 10, 13, 9),
              temp: 11,
              symbol: 'clearsky_day',
            ),
            metEntry(DateTime(2026, 10, 13, 10), temp: 14, rain: 0.5),
            metEntry(
              DateTime(2026, 10, 13, 11),
              temp: 16,
              symbol: 'partlycloudy_day',
            ),
            metEntry(
              DateTime(2026, 10, 14, 12),
              temp: 8,
              symbol: 'rain',
              rain: 1,
              hourly: false,
            ),
          ],
        },
      }, now: now);
      expect(r.now.condition, WeatherCondition.clearDay);
      expect(r.now.windSpeed, 18, reason: '5 m/s = 18 km/h');
      expect(r.daily.first.high, 16);
      expect(r.daily.first.low, 11);
      expect(r.daily.first.precipitation, closeTo(0.5, 0.01));
      expect(r.daily[1].condition, WeatherCondition.rain);
      expect(
        r.daily[1].precipitation,
        6,
        reason: '6-hour block used when not hourly',
      );
    });

    test('rejects malformed responses', () {
      expect(
        () => parseMetForecast({'properties': {}}, now: now),
        throwsA(anything),
      );
    });

    test('identifies the app and rounds coordinates to ~1 km', () async {
      final adapter = FakeAdapter(
        (_) => (
          200,
          {
            'properties': {
              'timeseries': [metEntry(DateTime.now())],
            },
          },
        ),
      );
      final client = MetNorwayClient(dio: Dio()..httpClientAdapter = adapter);
      await client.forecast(latitude: 44.817812, longitude: 20.456897);
      final req = adapter.requests.single;
      expect(req.uri.toString(), contains('locationforecast/2.0/compact'));
      expect(req.queryParameters, {'lat': 44.82, 'lon': 20.46});
      expect(req.headers['User-Agent'], MetNorwayClient.userAgent);
    });
  });

  group('device-location weather is opt-in', () {
    test('off by default; nothing is requested', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      expect(c.read(deviceWeatherEnabledProvider), isFalse);
      expect(await c.read(deviceWeatherProvider.future), isNull);
    });

    test('permission denied forever is reported, no request made', () async {
      final c = ProviderContainer(
        overrides: [
          ...await testOverrides(),
          deviceLocatorProvider.overrideWithValue(DeniedLocator()),
        ],
      );
      addTearDown(c.dispose);
      await c.read(deviceWeatherEnabledProvider.notifier).set(true);
      final state = await c.read(deviceWeatherProvider.future);
      expect(state, isA<DeviceWeatherNoLocation>());
    });
  });

  testWidgets(
    'dashboard shows home weather with forecast; device weather after consent',
    (tester) async {
      await pumpApp(tester, signedIn: true, size: const Size(800, 2200));
      await settle(tester, 12);
      expect(find.text(en.weatherAtHome), findsOneWidget);
      expect(find.text(en.weatherPartlyCloudy), findsWidgets);
      expect(find.text(en.summaryOutdoor), findsOneWidget);
      expect(
        find.byKey(const ValueKey('weather-device')),
        findsNothing,
        reason: 'opt-in',
      );

      await tapKey(tester, 'enableDeviceWeather');
      await settle(tester, 2);
      expect(find.text(en.weatherDeviceDisclosure), findsOneWidget);
      await tapKey(tester, 'confirmDeviceWeather');
      await settle(tester, 6);
      expect(find.byKey(const ValueKey('weather-device')), findsOneWidget);
      expect(find.text(en.weatherMetAttribution), findsOneWidget);

      await goTo(tester, '/settings');
      await tester.ensureVisible(find.byKey(const Key('deviceWeatherSwitch')));
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('deviceWeatherSwitch')),
            )
            .value,
        isTrue,
      );
      await unmount(tester);
    },
  );
}
