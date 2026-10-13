/// What a device *is*, independent of protocol or manufacturer.
///
/// A Zigbee, Matter and Wi-Fi bulb all become [dimmableLight] (or
/// [rgbLight] …) so the UI renders them identically. Extra generic kinds
/// ([sensor], [binarySensor], [batterySensor]) cover values that have no
/// more specific category.
enum DeviceKind {
  switchDevice,
  outlet,
  light,
  dimmableLight,
  rgbLight,
  rgbwLight,
  temperatureSensor,
  humiditySensor,
  pressureSensor,
  airQualitySensor,
  motionSensor,
  occupancySensor,
  contactSensor,
  smokeSensor,
  coSensor,
  waterLeakSensor,
  vibrationSensor,
  illuminanceSensor,
  batterySensor,
  sensor,
  binarySensor,
  thermostat,
  climate,
  lock,
  garageDoor,
  blind,
  curtain,
  camera,
  doorbell,
  mediaPlayer,
  speaker,
  television,
  energyMeter,
  powerMeter,
  waterMeter,
  gasMeter,
  vacuum,
  alarm,
  siren,
  fan,
  airPurifier,
  humidifier,
  dehumidifier,
  irrigation,
  button,
  scene,
  script,
  automation,

  /// A Home Assistant weather entity (shown in the weather card, not as
  /// a device).
  weather,

  /// A household member (Home Assistant `person`): home / away / zone.
  person,
  unknown;

  bool get isLight =>
      this == light ||
      this == dimmableLight ||
      this == rgbLight ||
      this == rgbwLight;

  /// Read-only devices that report a value or a binary condition.
  bool get isSensor => switch (this) {
    temperatureSensor ||
    humiditySensor ||
    pressureSensor ||
    airQualitySensor ||
    motionSensor ||
    occupancySensor ||
    contactSensor ||
    smokeSensor ||
    coSensor ||
    waterLeakSensor ||
    vibrationSensor ||
    illuminanceSensor ||
    batterySensor ||
    sensor ||
    binarySensor ||
    energyMeter ||
    powerMeter ||
    waterMeter ||
    gasMeter => true,
    _ => false,
  };

  /// Scenes, scripts and automations are not physical devices.
  bool get isRoutine => this == scene || this == script || this == automation;
}

/// Radio / transport the device uses, derived from the Home Assistant
/// integration that provides it. Informational only — never used to decide
/// how to control a device.
enum DeviceProtocol {
  zigbee,
  zwave,
  matter,
  thread,
  wifi,
  ethernet,
  mqtt,
  bluetooth,
  esphome,
  knx,
  modbus,
  rf433,
  infrared,
  cloud,
  virtual,
  unknown,
}
