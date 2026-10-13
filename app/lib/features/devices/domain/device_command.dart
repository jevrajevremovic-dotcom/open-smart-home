import 'package:flutter/foundation.dart';

import 'capability.dart';
import 'device_kind.dart';
import 'smart_home_device.dart';

/// A protocol-independent instruction for one device.
///
/// Each command names the capability it needs ([requiredCapability]); the
/// command service refuses commands the device does not declare.
@immutable
sealed class DeviceCommand {
  const DeviceCommand();

  Capability get requiredCapability;

  /// Commands with physical security impact (unlocking doors, disarming an
  /// alarm, opening a garage) must be confirmed by the user first.
  bool isCritical(SmartHomeDevice device) => false;
}

final class TurnOn extends DeviceCommand {
  const TurnOn();
  @override
  Capability get requiredCapability => Capability.power;
}

final class TurnOff extends DeviceCommand {
  const TurnOff();
  @override
  Capability get requiredCapability => Capability.power;
}

final class Toggle extends DeviceCommand {
  const Toggle();
  @override
  Capability get requiredCapability => Capability.power;
}

final class SetBrightness extends DeviceCommand {
  const SetBrightness(this.percent) : assert(percent >= 0 && percent <= 100);
  final int percent;
  @override
  Capability get requiredCapability => Capability.brightness;
}

final class SetColorTemperature extends DeviceCommand {
  const SetColorTemperature(this.kelvin);
  final int kelvin;
  @override
  Capability get requiredCapability => Capability.colorTemperature;
}

final class SetRgbColor extends DeviceCommand {
  const SetRgbColor(this.color);
  final RgbColor color;
  @override
  Capability get requiredCapability => Capability.rgb;
}

final class SetTargetTemperature extends DeviceCommand {
  const SetTargetTemperature(this.temperature);
  final double temperature;
  @override
  Capability get requiredCapability => Capability.targetTemperature;
}

final class SetHvacMode extends DeviceCommand {
  const SetHvacMode(this.mode);
  final String mode;
  @override
  Capability get requiredCapability => Capability.hvacMode;
}

final class SetFanMode extends DeviceCommand {
  const SetFanMode(this.mode);
  final String mode;
  @override
  Capability get requiredCapability => Capability.fanMode;
}

final class SetVolume extends DeviceCommand {
  const SetVolume(this.percent) : assert(percent >= 0 && percent <= 100);
  final int percent;
  @override
  Capability get requiredCapability => Capability.volume;
}

final class OpenCover extends DeviceCommand {
  const OpenCover();
  @override
  Capability get requiredCapability => Capability.open;
  @override
  bool isCritical(SmartHomeDevice device) =>
      device.kind == DeviceKind.garageDoor;
}

final class CloseCover extends DeviceCommand {
  const CloseCover();
  @override
  Capability get requiredCapability => Capability.close;
}

final class StopCover extends DeviceCommand {
  const StopCover();
  @override
  Capability get requiredCapability => Capability.stop;
}

final class SetCoverPosition extends DeviceCommand {
  const SetCoverPosition(this.percent) : assert(percent >= 0 && percent <= 100);
  final int percent;
  @override
  Capability get requiredCapability => Capability.position;
  @override
  bool isCritical(SmartHomeDevice device) =>
      device.kind == DeviceKind.garageDoor && percent > 0;
}

final class LockDevice extends DeviceCommand {
  const LockDevice();
  @override
  Capability get requiredCapability => Capability.lock;
}

final class UnlockDevice extends DeviceCommand {
  const UnlockDevice();
  @override
  Capability get requiredCapability => Capability.unlock;
  @override
  bool isCritical(SmartHomeDevice device) => true;
}

final class DisarmAlarm extends DeviceCommand {
  const DisarmAlarm({this.code});

  /// Alarm code, if the panel requires one. Never logged.
  final String? code;
  @override
  Capability get requiredCapability => Capability.disarm;
  @override
  bool isCritical(SmartHomeDevice device) => true;
}

/// Runs a scene/script, presses a button or triggers an automation.
final class Activate extends DeviceCommand {
  const Activate();
  @override
  Capability get requiredCapability => Capability.trigger;
}
