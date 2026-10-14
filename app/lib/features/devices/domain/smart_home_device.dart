import 'package:flutter/foundation.dart';

import 'capability.dart';
import 'device_kind.dart';

enum CoverState { open, closed, opening, closing }

enum DoorLockState {
  locked,
  unlocked,
  locking,
  unlocking,
  jammed,
  open,
  opening,
}

enum AlarmState {
  disarmed,
  armedHome,
  armedAway,
  armedNight,
  armedVacation,
  armedCustomBypass,
  arming,
  disarming,
  pending,
  triggered,
}

@immutable
class RgbColor {
  const RgbColor(this.red, this.green, this.blue);

  final int red;
  final int green;
  final int blue;

  @override
  bool operator ==(Object other) =>
      other is RgbColor &&
      other.red == red &&
      other.green == green &&
      other.blue == blue;

  @override
  int get hashCode => Object.hash(red, green, blue);

  @override
  String toString() => 'rgb($red, $green, $blue)';
}

/// Current values, normalised to app units (percent 0–100, Kelvin, …).
/// Fields irrelevant to a device stay `null`; `null` also means "not
/// reported", which the UI must show as unknown rather than as zero.
@immutable
class DeviceState {
  const DeviceState({
    required this.raw,
    this.isOn,
    this.brightnessPercent,
    this.colorTemperatureKelvin,
    this.rgb,
    this.currentTemperature,
    this.targetTemperature,
    this.targetTemperatureLow,
    this.targetTemperatureHigh,
    this.hvacMode,
    this.hvacAction,
    this.fanMode,
    this.swingMode,
    this.presetMode,
    this.currentHumidity,
    this.targetHumidity,
    this.coverState,
    this.position,
    this.tiltPosition,
    this.lockState,
    this.alarmState,
    this.isActive,
    this.numericValue,
    this.textValue,
    this.unit,
    this.volumePercent,
    this.isMuted,
    this.source,
    this.mediaTitle,
    this.mediaArtist,
    this.lastTriggered,
    this.windSpeed,
    this.windSpeedUnit,
    this.percentage,
    this.oscillating,
  });

  /// Home Assistant's state string, kept for diagnostics.
  final String raw;

  final bool? isOn;
  final int? brightnessPercent;
  final int? colorTemperatureKelvin;
  final RgbColor? rgb;

  final double? currentTemperature;
  final double? targetTemperature;
  final double? targetTemperatureLow;
  final double? targetTemperatureHigh;
  final String? hvacMode;

  /// What the device is doing right now (`heating`, `cooling`, `idle`, …).
  final String? hvacAction;
  final String? fanMode;
  final String? swingMode;
  final String? presetMode;
  final double? currentHumidity;
  final double? targetHumidity;

  final CoverState? coverState;

  /// 0 = closed, 100 = fully open.
  final int? position;
  final int? tiltPosition;

  final DoorLockState? lockState;
  final AlarmState? alarmState;

  /// Binary sensors: `true` = detected / open / wet / …
  final bool? isActive;

  /// Numeric sensor reading in [unit].
  final double? numericValue;

  /// Non-numeric sensor reading (e.g. an enum sensor).
  final String? textValue;
  final String? unit;

  final int? volumePercent;
  final bool? isMuted;
  final String? source;
  final String? mediaTitle;

  /// Artist, or the album / channel / app when there is no artist.
  final String? mediaArtist;

  /// Automations and scripts.
  final DateTime? lastTriggered;

  /// Weather entities.
  final double? windSpeed;
  final String? windSpeedUnit;

  /// Fan speed 0–100.
  final int? percentage;
  final bool? oscillating;
}

/// Allowed ranges and options, so controls never offer invalid values.
@immutable
class DeviceLimits {
  const DeviceLimits({
    this.minColorTemperatureKelvin,
    this.maxColorTemperatureKelvin,
    this.minTemperature,
    this.maxTemperature,
    this.temperatureStep,
    this.minHumidity,
    this.maxHumidity,
    this.hvacModes = const [],
    this.fanModes = const [],
    this.swingModes = const [],
    this.presetModes = const [],
    this.sources = const [],
    this.alarmArmModes = const [],
    this.alarmCodeFormat,
    this.alarmCodeArmRequired = false,
    this.options = const [],
    this.minValue,
    this.maxValue,
    this.valueStep,
    this.percentageStep,
  });

  static const DeviceLimits none = DeviceLimits();

  final int? minColorTemperatureKelvin;
  final int? maxColorTemperatureKelvin;
  final double? minTemperature;
  final double? maxTemperature;
  final double? temperatureStep;
  final double? minHumidity;
  final double? maxHumidity;
  final List<String> hvacModes;
  final List<String> fanModes;
  final List<String> swingModes;
  final List<String> presetModes;
  final List<String> sources;

  /// Arm modes the alarm panel offers (`home`, `away`, `night`,
  /// `vacation`, `custom_bypass`).
  final List<String> alarmArmModes;

  /// `number`, `text` or `null` (no code).
  final String? alarmCodeFormat;
  final bool alarmCodeArmRequired;

  /// Choices of a select.
  final List<String> options;

  /// Range of a number entity.
  final double? minValue;
  final double? maxValue;
  final double? valueStep;

  /// Fan speed step (e.g. 33.33 for a 3-speed fan).
  final double? percentageStep;
}

@immutable
class DeviceMetadata {
  const DeviceMetadata({
    this.batteryPercent,
    this.batteryLow,
    this.signalStrength,
    this.signalUnit,
    this.haDeviceClass,
    this.lastChanged,
    this.lastUpdated,
    this.picturePath,
    this.configId,
  });

  /// From a battery sensor of the same physical device, if any.
  final int? batteryPercent;

  /// From a `battery` binary sensor of the same physical device, if any.
  final bool? batteryLow;
  final double? signalStrength;
  final String? signalUnit;

  /// Home Assistant `device_class` attribute, kept for icon selection.
  final String? haDeviceClass;
  final DateTime? lastChanged;
  final DateTime? lastUpdated;

  /// `entity_picture` when it is a path on the Home Assistant server
  /// (`/api/...`). External URLs are dropped: the app never sends the
  /// token to, or loads pictures from, other hosts.
  final String? picturePath;

  /// Id of a UI-managed automation/script (attribute `id`), needed to
  /// delete it.
  final String? configId;
}

/// The protocol-independent device model the whole UI works with.
@immutable
class SmartHomeDevice {
  const SmartHomeDevice({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.kind,
    required this.available,
    required this.capabilities,
    required this.state,
    this.deviceId,
    this.roomId,
    this.protocol = DeviceProtocol.unknown,
    this.manufacturer,
    this.model,
    this.limits = DeviceLimits.none,
    this.metadata = const DeviceMetadata(),
    this.isAuxiliary = false,
  });

  /// Stable app id. Equal to [sourceId] for Home Assistant entities.
  final String id;

  /// Id in the source system (Home Assistant `entity_id`).
  final String sourceId;

  /// Home Assistant device-registry id, shared by entities of one device.
  final String? deviceId;
  final String name;
  final String? roomId;
  final DeviceKind kind;
  final DeviceProtocol protocol;
  final String? manufacturer;
  final String? model;

  /// `false` when Home Assistant reports the entity as `unavailable`.
  final bool available;
  final Set<Capability> capabilities;
  final DeviceState state;
  final DeviceLimits limits;
  final DeviceMetadata metadata;

  /// Hidden, configuration or diagnostic entities. Kept (they feed
  /// metadata such as battery) but not shown in normal lists.
  final bool isAuxiliary;

  bool supports(Capability capability) => capabilities.contains(capability);

  /// Low battery: ≤ 15 % or a battery-low binary sensor is on.
  bool get hasLowBattery =>
      metadata.batteryLow == true ||
      (metadata.batteryPercent != null && metadata.batteryPercent! <= 15);

  @override
  String toString() =>
      'SmartHomeDevice($id, ${kind.name}, available: $available)';
}

/// An area / room.
@immutable
class Room {
  const Room({required this.id, required this.name, this.icon, this.picture});

  final String id;
  final String name;

  /// Material Design Icons name from Home Assistant, e.g. `mdi:sofa`.
  final String? icon;
  final String? picture;

  @override
  bool operator ==(Object other) =>
      other is Room &&
      other.id == id &&
      other.name == name &&
      other.icon == icon &&
      other.picture == picture;

  @override
  int get hashCode => Object.hash(id, name, icon, picture);
}
