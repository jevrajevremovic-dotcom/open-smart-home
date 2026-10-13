import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n.dart';
import '../domain/capability.dart';
import '../domain/device_kind.dart';
import '../domain/smart_home_device.dart';

/// Visual emphasis of a device's current state.
enum DeviceTone {
  /// Off / idle / closed.
  neutral,

  /// On, open, running — positive activity.
  active,

  /// Needs attention (open lock, low battery, jammed).
  warning,

  /// Danger (smoke, CO, water leak, alarm triggered).
  critical,

  /// Unavailable.
  unavailable,
}

/// Icon, tone and localized status text for a device. Pure functions of the
/// device model, so every screen describes devices the same way.
abstract final class DevicePresentation {
  static IconData icon(SmartHomeDevice d) {
    final on = d.state.isOn == true;
    final active = d.state.isActive == true;
    return switch (d.kind) {
      DeviceKind.light ||
      DeviceKind.dimmableLight ||
      DeviceKind.rgbLight ||
      DeviceKind.rgbwLight => on ? Icons.lightbulb : Icons.lightbulb_outline,
      DeviceKind.switchDevice =>
        on ? Icons.toggle_on : Icons.toggle_off_outlined,
      DeviceKind.outlet => on ? Icons.power : Icons.power_outlined,
      DeviceKind.temperatureSensor => Icons.thermostat,
      DeviceKind.humiditySensor => Icons.water_drop_outlined,
      DeviceKind.pressureSensor => Icons.speed,
      DeviceKind.airQualitySensor => Icons.air,
      DeviceKind.motionSensor => active ? Icons.directions_run : Icons.sensors,
      DeviceKind.occupancySensor =>
        active ? Icons.person : Icons.person_outline,
      DeviceKind.contactSensor => _contactIcon(d, active),
      DeviceKind.smokeSensor => Icons.local_fire_department_outlined,
      DeviceKind.coSensor => Icons.co2,
      DeviceKind.waterLeakSensor =>
        active ? Icons.water_damage : Icons.water_damage_outlined,
      DeviceKind.vibrationSensor => Icons.vibration,
      DeviceKind.illuminanceSensor => Icons.light_mode_outlined,
      DeviceKind.batterySensor => Icons.battery_std,
      DeviceKind.sensor => Icons.sensors,
      DeviceKind.binarySensor => Icons.radio_button_checked,
      DeviceKind.thermostat => Icons.thermostat_auto,
      DeviceKind.climate => Icons.ac_unit,
      DeviceKind.lock => switch (d.state.lockState) {
        DoorLockState.unlocked || DoorLockState.open => Icons.lock_open,
        _ => Icons.lock_outline,
      },
      DeviceKind.garageDoor => Icons.garage_outlined,
      DeviceKind.blind || DeviceKind.curtain => Icons.blinds_outlined,
      DeviceKind.camera => Icons.videocam_outlined,
      DeviceKind.doorbell => Icons.doorbell_outlined,
      DeviceKind.mediaPlayer => Icons.play_circle_outline,
      DeviceKind.speaker => Icons.speaker,
      DeviceKind.television => Icons.tv,
      DeviceKind.energyMeter => Icons.electric_meter_outlined,
      DeviceKind.powerMeter => Icons.bolt,
      DeviceKind.waterMeter => Icons.water_outlined,
      DeviceKind.gasMeter => Icons.gas_meter_outlined,
      DeviceKind.vacuum => Icons.cleaning_services_outlined,
      DeviceKind.alarm => Icons.shield_outlined,
      DeviceKind.siren => Icons.campaign_outlined,
      DeviceKind.fan || DeviceKind.airPurifier => Icons.mode_fan_off_outlined,
      DeviceKind.humidifier || DeviceKind.dehumidifier => Icons.water_drop,
      DeviceKind.irrigation => Icons.water,
      DeviceKind.button => Icons.radio_button_unchecked,
      DeviceKind.scene => Icons.palette_outlined,
      DeviceKind.script => Icons.description_outlined,
      DeviceKind.automation => Icons.auto_mode,
      DeviceKind.unknown => Icons.device_unknown_outlined,
    };
  }

  static IconData _contactIcon(SmartHomeDevice d, bool open) =>
      switch (d.metadata.haDeviceClass) {
        'window' => open ? Icons.window : Icons.window_outlined,
        'garage_door' => Icons.garage_outlined,
        _ => open ? Icons.door_front_door : Icons.door_front_door_outlined,
      };

  static DeviceTone tone(SmartHomeDevice d) {
    if (!d.available) return DeviceTone.unavailable;
    final s = d.state;
    final active = s.isActive == true;
    switch (d.kind) {
      case DeviceKind.smokeSensor ||
          DeviceKind.coSensor ||
          DeviceKind.waterLeakSensor:
        return active ? DeviceTone.critical : DeviceTone.neutral;
      case DeviceKind.alarm:
        return s.alarmState == AlarmState.triggered
            ? DeviceTone.critical
            : DeviceTone.neutral;
      case DeviceKind.lock:
        return switch (s.lockState) {
          DoorLockState.jammed => DeviceTone.critical,
          DoorLockState.unlocked || DoorLockState.open => DeviceTone.warning,
          _ => DeviceTone.neutral,
        };
      case DeviceKind.contactSensor ||
          DeviceKind.motionSensor ||
          DeviceKind.occupancySensor:
        return active ? DeviceTone.active : DeviceTone.neutral;
      case DeviceKind.blind || DeviceKind.curtain || DeviceKind.garageDoor:
        return s.coverState == CoverState.closed
            ? DeviceTone.neutral
            : DeviceTone.active;
      default:
        if (d.hasLowBattery) return DeviceTone.warning;
        return s.isOn == true ? DeviceTone.active : DeviceTone.neutral;
    }
  }

  /// One-line status, e.g. "On · 75 %", "22.4 °C", "Locked".
  static String status(AppLocalizations l10n, SmartHomeDevice d) {
    if (!d.available) return l10n.stateUnavailable;
    final s = d.state;
    final locale = l10n.localeName;
    String onOff() => switch (s.isOn) {
      true => l10n.stateOn,
      false => l10n.stateOff,
      null => l10n.stateUnknown,
    };
    String binary(String yes, String no) => switch (s.isActive) {
      true => yes,
      false => no,
      null => l10n.stateUnknown,
    };

    return switch (d.kind) {
      DeviceKind.light ||
      DeviceKind.dimmableLight ||
      DeviceKind.rgbLight ||
      DeviceKind.rgbwLight =>
        s.isOn == true && s.brightnessPercent != null
            ? l10n.stateOnBrightness(s.brightnessPercent!)
            : onOff(),
      DeviceKind.motionSensor => binary(l10n.motionDetected, l10n.motionClear),
      DeviceKind.occupancySensor => binary(
        l10n.occupancyDetected,
        l10n.occupancyClear,
      ),
      DeviceKind.contactSensor => binary(l10n.contactOpen, l10n.contactClosed),
      DeviceKind.smokeSensor => binary(l10n.smokeDetected, l10n.smokeClear),
      DeviceKind.coSensor => binary(l10n.coDetected, l10n.coClear),
      DeviceKind.waterLeakSensor => binary(l10n.leakDetected, l10n.leakClear),
      DeviceKind.vibrationSensor => binary(
        l10n.vibrationDetected,
        l10n.vibrationClear,
      ),
      DeviceKind.binarySensor => binary(l10n.binaryActive, l10n.binaryInactive),
      DeviceKind.thermostat || DeviceKind.climate => _climate(l10n, d),
      DeviceKind.blind ||
      DeviceKind.curtain ||
      DeviceKind.garageDoor => _cover(l10n, s),
      DeviceKind.irrigation => _cover(l10n, s),
      DeviceKind.lock => switch (s.lockState) {
        DoorLockState.locked => l10n.lockLocked,
        DoorLockState.unlocked => l10n.lockUnlocked,
        DoorLockState.locking => l10n.lockLocking,
        DoorLockState.unlocking => l10n.lockUnlocking,
        DoorLockState.jammed => l10n.lockJammed,
        DoorLockState.open || DoorLockState.opening => l10n.contactOpen,
        null => l10n.stateUnknown,
      },
      DeviceKind.alarm => switch (s.alarmState) {
        AlarmState.disarmed => l10n.alarmDisarmed,
        AlarmState.triggered => l10n.alarmTriggered,
        AlarmState.arming => l10n.alarmArming,
        AlarmState.pending => l10n.alarmPending,
        AlarmState.disarming => l10n.alarmDisarmed,
        null => l10n.stateUnknown,
        _ => l10n.alarmArmed,
      },
      DeviceKind.camera => switch (s.raw) {
        'streaming' => l10n.cameraStreaming,
        'recording' => l10n.cameraRecording,
        _ => l10n.cameraIdle,
      },
      DeviceKind.mediaPlayer ||
      DeviceKind.speaker ||
      DeviceKind.television => switch (s.raw) {
        'playing' => s.mediaTitle ?? l10n.mediaPlaying,
        'paused' => l10n.mediaPaused,
        _ => onOff(),
      },
      DeviceKind.doorbell =>
        s.lastTriggered == null
            ? l10n.stateUnknown
            : l10n.doorbellLast(formatDateTime(locale, s.lastTriggered!)),
      DeviceKind.scene || DeviceKind.button => l10n.routineReady,
      DeviceKind.script =>
        s.isOn == true ? l10n.scriptRunning : l10n.routineReady,
      DeviceKind.automation => onOff(),
      DeviceKind.unknown => s.raw,
      _ when d.kind.isSensor => sensorValue(l10n, s),
      _ => onOff(),
    };
  }

  static String _climate(AppLocalizations l10n, SmartHomeDevice d) {
    final s = d.state;
    final mode = hvacModeLabel(l10n, s.hvacMode);
    if (s.hvacMode == 'off' || s.targetTemperature == null) return mode;
    return l10n.climateStatus(
      mode,
      formatNumber(l10n.localeName, s.targetTemperature!, unit: '°'),
    );
  }

  static String _cover(AppLocalizations l10n, DeviceState s) =>
      switch (s.coverState) {
        CoverState.opening => l10n.coverOpening,
        CoverState.closing => l10n.coverClosing,
        CoverState.closed => l10n.contactClosed,
        CoverState.open when s.position != null && s.position! < 100 =>
          l10n.coverOpenPercent(s.position!),
        CoverState.open => l10n.contactOpen,
        null => l10n.stateUnknown,
      };

  static String sensorValue(AppLocalizations l10n, DeviceState s) {
    if (s.numericValue != null) {
      return formatNumber(l10n.localeName, s.numericValue!, unit: s.unit);
    }
    return s.textValue ?? l10n.stateUnknown;
  }

  static String hvacModeLabel(AppLocalizations l10n, String? mode) =>
      switch (mode) {
        'off' => l10n.hvacOff,
        'heat' => l10n.hvacHeat,
        'cool' => l10n.hvacCool,
        'heat_cool' => l10n.hvacHeatCool,
        'auto' => l10n.hvacAuto,
        'dry' => l10n.hvacDry,
        'fan_only' => l10n.hvacFanOnly,
        null => l10n.stateUnknown,
        // Unknown values come from integrations; show them as reported.
        final other => other,
      };

  static String protocolLabel(AppLocalizations l10n, DeviceProtocol p) =>
      switch (p) {
        DeviceProtocol.zigbee => 'Zigbee',
        DeviceProtocol.zwave => 'Z-Wave',
        DeviceProtocol.matter => 'Matter',
        DeviceProtocol.thread => 'Thread',
        DeviceProtocol.wifi => 'Wi-Fi',
        DeviceProtocol.ethernet => 'Ethernet',
        DeviceProtocol.mqtt => 'MQTT',
        DeviceProtocol.bluetooth => 'Bluetooth',
        DeviceProtocol.esphome => 'ESPHome',
        DeviceProtocol.knx => 'KNX',
        DeviceProtocol.modbus => 'Modbus',
        DeviceProtocol.rf433 => '433 MHz',
        DeviceProtocol.infrared => 'IR',
        DeviceProtocol.cloud => l10n.protocolCloud,
        DeviceProtocol.virtual => l10n.protocolVirtual,
        DeviceProtocol.unknown => l10n.stateUnknown,
      };

  /// Whether the tile offers a one-tap action.
  static bool hasQuickToggle(SmartHomeDevice d) =>
      d.supports(Capability.power) &&
      !d.kind.isRoutine &&
      d.kind != DeviceKind.climate &&
      d.kind != DeviceKind.thermostat;

  static bool hasQuickActivate(SmartHomeDevice d) =>
      d.kind == DeviceKind.scene ||
      d.kind == DeviceKind.script ||
      d.kind == DeviceKind.button;
}

String formatNumber(String locale, double value, {String? unit}) {
  final format = NumberFormat.decimalPattern(locale)..maximumFractionDigits = 1;
  final number = format.format(value);
  if (unit == null || unit.isEmpty) return number;
  // Degree-like units attach directly ("22,4 °C" keeps a space, "23°" not).
  return unit == '°' ? '$number°' : '$number $unit';
}

String formatDateTime(String locale, DateTime time) {
  final local = time.toLocal();
  final now = DateTime.now();
  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  return sameDay
      ? DateFormat.Hm(locale).format(local)
      : DateFormat.yMd(locale).add_Hm().format(local);
}

extension DeviceToneColors on DeviceTone {
  Color color(
    ColorScheme scheme, {
    required Color warning,
    required Color critical,
    required Color unavailable,
  }) => switch (this) {
    DeviceTone.neutral => scheme.onSurfaceVariant,
    DeviceTone.active => scheme.primary,
    DeviceTone.warning => warning,
    DeviceTone.critical => critical,
    DeviceTone.unavailable => unavailable,
  };
}
