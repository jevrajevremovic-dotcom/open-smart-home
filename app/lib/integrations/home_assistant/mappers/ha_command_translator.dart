import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../../../features/devices/domain/device_command.dart';
import '../../../features/devices/domain/smart_home_device.dart';

/// A Home Assistant service call (`POST /api/services/<domain>/<service>`).
@immutable
class HaServiceCall {
  const HaServiceCall(this.domain, this.service, this.data);

  final String domain;
  final String service;
  final Map<String, Object?> data;

  @override
  String toString() => '$domain.$service(${data['entity_id']})';
}

/// Translates protocol-independent [DeviceCommand]s into documented Home
/// Assistant services. Values are clamped to the device's limits and modes
/// are validated against the options the device reports.
class HaCommandTranslator {
  const HaCommandTranslator();

  static const _toggleDomains = {
    'light',
    'switch',
    'input_boolean',
    'fan',
    'automation',
    'media_player',
    'humidifier',
    'climate',
    'siren',
  };

  HaServiceCall translate(SmartHomeDevice device, DeviceCommand command) {
    final entityId = device.sourceId;
    final domain = entityId.substring(0, entityId.indexOf('.'));
    final target = <String, Object?>{'entity_id': entityId};
    HaServiceCall call(
      String service, [
      Map<String, Object?> extra = const {},
    ]) => HaServiceCall(domain, service, {...target, ...extra});
    HaServiceCall unsupported() => throw AppFailure(
      FailureKind.unsupportedFeature,
      debugMessage: '${command.runtimeType} not supported for domain $domain',
    );

    switch (command) {
      case TurnOn():
        return call('turn_on');
      case TurnOff():
        return call('turn_off');
      case Toggle():
        if (_toggleDomains.contains(domain)) return call('toggle');
        return call(device.state.isOn == true ? 'turn_off' : 'turn_on');

      case SetBrightness(:final percent):
        if (domain != 'light') return unsupported();
        return percent == 0
            ? call('turn_off')
            : call('turn_on', {'brightness_pct': percent});
      case SetColorTemperature(:final kelvin):
        if (domain != 'light') return unsupported();
        final min = device.limits.minColorTemperatureKelvin;
        final max = device.limits.maxColorTemperatureKelvin;
        final value = (min != null && max != null)
            ? kelvin.clamp(min, max)
            : kelvin;
        return call('turn_on', {'color_temp_kelvin': value});
      case SetRgbColor(:final color):
        if (domain != 'light') return unsupported();
        int c(int v) => v.clamp(0, 255);
        return call('turn_on', {
          'rgb_color': [c(color.red), c(color.green), c(color.blue)],
        });

      case SetTargetTemperature(:final temperature):
        if (domain != 'climate') return unsupported();
        return call('set_temperature', {
          'temperature': _clampTemperature(device, temperature),
        });
      case SetHvacMode(:final mode):
        if (domain != 'climate') return unsupported();
        _requireOption(mode, device.limits.hvacModes, 'hvac_mode');
        return call('set_hvac_mode', {'hvac_mode': mode});
      case SetFanMode(:final mode):
        if (domain != 'climate') return unsupported();
        _requireOption(mode, device.limits.fanModes, 'fan_mode');
        return call('set_fan_mode', {'fan_mode': mode});

      case OpenCover():
        return switch (domain) {
          'cover' => call('open_cover'),
          'valve' => call('open_valve'),
          'lock' => call('open'),
          _ => unsupported(),
        };
      case CloseCover():
        return switch (domain) {
          'cover' => call('close_cover'),
          'valve' => call('close_valve'),
          _ => unsupported(),
        };
      case StopCover():
        return switch (domain) {
          'cover' => call('stop_cover'),
          'valve' => call('stop_valve'),
          'vacuum' => call('stop'),
          _ => unsupported(),
        };
      case SetCoverPosition(:final percent):
        return switch (domain) {
          'cover' => call('set_cover_position', {'position': percent}),
          'valve' => call('set_valve_position', {'position': percent}),
          _ => unsupported(),
        };

      case LockDevice():
        return domain == 'lock' ? call('lock') : unsupported();
      case UnlockDevice():
        return domain == 'lock' ? call('unlock') : unsupported();
      case DisarmAlarm(:final code):
        if (domain != 'alarm_control_panel') return unsupported();
        return call('alarm_disarm', {'code': ?code});

      case Activate():
        return switch (domain) {
          'scene' || 'script' => call('turn_on'),
          'button' || 'input_button' => call('press'),
          'automation' => call('trigger'),
          _ => unsupported(),
        };
    }
  }

  double _clampTemperature(SmartHomeDevice device, double value) {
    final limits = device.limits;
    final step = limits.temperatureStep ?? 0.5;
    var v = (value / step).round() * step;
    if (limits.minTemperature != null && v < limits.minTemperature!) {
      v = limits.minTemperature!;
    }
    if (limits.maxTemperature != null && v > limits.maxTemperature!) {
      v = limits.maxTemperature!;
    }
    return double.parse(v.toStringAsFixed(2));
  }

  void _requireOption(String value, List<String> allowed, String field) {
    if (allowed.isNotEmpty && !allowed.contains(value)) {
      throw AppFailure(
        FailureKind.validation,
        debugMessage: '$field "$value" not offered by device',
      );
    }
  }
}
