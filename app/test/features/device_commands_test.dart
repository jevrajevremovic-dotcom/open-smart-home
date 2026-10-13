import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_smart_home/core/errors/app_failure.dart';
import 'package:open_smart_home/features/devices/application/device_command_service.dart';
import 'package:open_smart_home/features/devices/domain/device_command.dart';
import 'package:open_smart_home/features/devices/domain/smart_home_device.dart';
import 'package:open_smart_home/integrations/home_assistant/api/home_assistant_api.dart';
import 'package:open_smart_home/integrations/home_assistant/mappers/ha_command_translator.dart';
import 'package:open_smart_home/integrations/home_assistant/mappers/ha_device_mapper.dart';
import 'package:open_smart_home/integrations/home_assistant/models/ha_models.dart';
import 'package:open_smart_home/integrations/home_assistant/models/ha_registry.dart';

class MockApi extends Mock implements HomeAssistantApi {}

SmartHomeDevice device(
  String id,
  String state, [
  Map<String, Object?> attrs = const {},
]) => const HaDeviceMapper().map(
  HaEntityState(entityId: id, state: state, attributes: attrs),
  HaRegistries.empty,
);

final dimmable = device('light.desk', 'on', {
  'supported_color_modes': ['color_temp'],
  'min_color_temp_kelvin': 2700,
  'max_color_temp_kelvin': 6500,
});
final onOffLight = device('light.hall', 'off', {
  'supported_color_modes': ['onoff'],
});
final ac = device('climate.ac', 'cool', {
  'hvac_modes': ['off', 'cool', 'heat'],
  'fan_modes': ['auto', 'low'],
  'min_temp': 16,
  'max_temp': 30,
  'target_temp_step': 0.5,
  'supported_features': 1 | 8,
});
final lock = device('lock.door', 'locked');
final garage = device('cover.garage', 'closed', {
  'device_class': 'garage',
  'supported_features': 3,
});

void main() {
  const t = HaCommandTranslator();

  group('HaCommandTranslator', () {
    test('lights', () {
      final on = t.translate(dimmable, const SetBrightness(40));
      expect((on.domain, on.service), ('light', 'turn_on'));
      expect(on.data, {'entity_id': 'light.desk', 'brightness_pct': 40});
      expect(t.translate(dimmable, const SetBrightness(0)).service, 'turn_off');
      expect(
        t
            .translate(dimmable, const SetColorTemperature(9000))
            .data['color_temp_kelvin'],
        6500,
      );
      expect(t.translate(onOffLight, const Toggle()).service, 'toggle');
    });

    test('climate clamps and rounds to the device step', () {
      expect(
        t.translate(ac, const SetTargetTemperature(22.3)).data['temperature'],
        22.5,
      );
      expect(
        t.translate(ac, const SetTargetTemperature(40)).data['temperature'],
        30,
      );
      expect(
        t.translate(ac, const SetHvacMode('heat')).data['hvac_mode'],
        'heat',
      );
      expect(
        () => t.translate(ac, const SetHvacMode('dry')),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.kind,
            'kind',
            FailureKind.validation,
          ),
        ),
      );
    });

    test('routines', () {
      expect(
        t.translate(device('scene.x', 'unknown'), const Activate()).toString(),
        'scene.turn_on(scene.x)',
      );
      expect(
        t.translate(device('button.x', 'unknown'), const Activate()).service,
        'press',
      );
      expect(
        t.translate(device('automation.x', 'on'), const Activate()).service,
        'trigger',
      );
    });

    test('alarm code is sent only when given', () {
      final panel = device('alarm_control_panel.home', 'armed_away');
      expect(
        t.translate(panel, const DisarmAlarm()).data.containsKey('code'),
        isFalse,
      );
      expect(
        t.translate(panel, const DisarmAlarm(code: '1234')).data['code'],
        '1234',
      );
    });

    test('media volume is sent as 0–1', () {
      final tv = device('media_player.tv', 'on', {'supported_features': 4});
      expect(t.translate(tv, const SetVolume(35)).data['volume_level'], 0.35);
    });

    test('wrong domain is rejected', () {
      expect(
        () => t.translate(lock, const SetBrightness(10)),
        throwsA(isA<AppFailure>()),
      );
    });
  });

  group('DeviceCommandService guards', () {
    late MockApi api;
    late DeviceCommandService service;

    setUp(() {
      api = MockApi();
      when(() => api.callService(any(), any(), data: any(named: 'data')))
          .thenAnswer((_) async => const []);
      service = DeviceCommandService(api);
    });

    Future<void> expectKind(Future<void> f, FailureKind kind) => expectLater(
      f,
      throwsA(isA<AppFailure>().having((e) => e.kind, 'kind', kind)),
    );

    test('sends supported commands', () async {
      await service.execute(dimmable, const SetBrightness(30));
      verify(
        () => api.callService(
          'light',
          'turn_on',
          data: {'entity_id': 'light.desk', 'brightness_pct': 30},
        ),
      ).called(1);
    });

    test(
      'refuses unsupported capabilities without calling the server',
      () async {
        await expectKind(
          service.execute(onOffLight, const SetBrightness(30)),
          FailureKind.unsupportedFeature,
        );
        verifyNever(
          () => api.callService(any(), any(), data: any(named: 'data')),
        );
      },
    );

    test('refuses unavailable devices', () async {
      final gone = device('switch.x', 'unavailable');
      await expectKind(
        service.execute(gone, const TurnOn()),
        FailureKind.unavailableEntity,
      );
      verifyNever(
        () => api.callService(any(), any(), data: any(named: 'data')),
      );
    });

    test('critical commands need confirmation', () async {
      await expectKind(
        service.execute(lock, const UnlockDevice()),
        FailureKind.confirmationRequired,
      );
      await expectKind(
        service.execute(garage, const OpenCover()),
        FailureKind.confirmationRequired,
      );
      await service.execute(
        lock,
        const LockDevice(),
      ); // locking is not critical
      await service.execute(lock, const UnlockDevice(), confirmed: true);
      verify(
        () =>
            api.callService('lock', 'unlock', data: {'entity_id': 'lock.door'}),
      ).called(1);
    });
  });
}
