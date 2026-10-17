import 'package:flutter/foundation.dart';

import '../../clap/clap_detector.dart';
import 'kiosk_layout.dart';

/// Gradient behind the kiosk dashboard's glass panels.
enum KioskBackground { aurora, ocean, dusk, forest }

/// The kiosk's look: solid dark "bubble" cards with pastel highlights
/// for what is on, or frosted glass over a gradient.
enum KioskStyle { bubble, glass }

/// Wall-panel options, stored locally (non-secret; the PIN only as a
/// salted PBKDF2 hash).
@immutable
class KioskSettings {
  const KioskSettings({
    this.startInKiosk = false,
    this.keepScreenOn = true,
    this.dimAfter = const Duration(minutes: 2),
    this.returnHomeAfter = const Duration(seconds: 60),
    this.pinHash,
    this.pinSalt,
    this.style = KioskStyle.bubble,
    this.background = KioskBackground.aurora,
    this.liteEffects = false,
    this.statusEntityIds = const [],
    this.showCameras = true,
    this.showCalendar = true,
    this.photoPath,
    this.clapEnabled = false,
    this.clapTargetId,
    this.clapSensitivity = ClapSensitivity.medium,
    this.popupTriggerIds = const [],
    this.popupCameraId,
    this.popupSeconds = 60,
    this.popupLive = true,
    this.nightBrightness = false,
    this.nightFrom = 22 * 60,
    this.nightTo = 7 * 60,
    this.nightLevel = 0.15,
    this.darkScreensaver = true,
    this.layout,
  });

  factory KioskSettings.fromJson(Map<String, Object?>? json) {
    if (json == null) return const KioskSettings();
    Duration? seconds(Object? v) =>
        v is int ? (v <= 0 ? Duration.zero : Duration(seconds: v)) : null;
    const d = KioskSettings();
    return KioskSettings(
      startInKiosk: json['startInKiosk'] == true,
      keepScreenOn: json['keepScreenOn'] != false,
      dimAfter: seconds(json['dimAfterSeconds']) ?? d.dimAfter,
      returnHomeAfter:
          seconds(json['returnHomeAfterSeconds']) ?? d.returnHomeAfter,
      pinHash: json['pinHash'] is String ? json['pinHash']! as String : null,
      pinSalt: json['pinSalt'] is String ? json['pinSalt']! as String : null,
      style: KioskStyle.values.firstWhere(
        (v) => v.name == json['style'],
        orElse: () => d.style,
      ),
      background: KioskBackground.values.firstWhere(
        (b) => b.name == json['background'],
        orElse: () => d.background,
      ),
      liteEffects: json['liteEffects'] == true,
      showCameras: json['showCameras'] != false,
      showCalendar: json['showCalendar'] != false,
      photoPath: json['photoPath'] is String
          ? json['photoPath']! as String
          : null,
      clapEnabled: json['clapEnabled'] == true,
      clapTargetId: json['clapTargetId'] is String
          ? json['clapTargetId']! as String
          : null,
      clapSensitivity: ClapSensitivity.values.firstWhere(
        (s) => s.name == json['clapSensitivity'],
        orElse: () => d.clapSensitivity,
      ),
      nightBrightness: json['nightBrightness'] == true,
      nightFrom: _minutes(json['nightFrom']) ?? d.nightFrom,
      nightTo: _minutes(json['nightTo']) ?? d.nightTo,
      nightLevel: switch (json['nightLevel']) {
        final num v => v.toDouble().clamp(0.02, 1.0),
        _ => d.nightLevel,
      },
      darkScreensaver: json['darkScreensaver'] != false,
      layout: KioskLayout.tryParse(json['layout']),
      popupTriggerIds: [
        if (json['popupTriggerIds'] case final List<Object?> ids)
          for (final id in ids.whereType<String>().take(10)) id,
      ],
      popupCameraId: json['popupCameraId'] is String
          ? json['popupCameraId']! as String
          : null,
      popupLive: json['popupLive'] != false,
      popupSeconds: switch (json['popupSeconds']) {
        final int s when popupOptions.contains(s) => s,
        _ => d.popupSeconds,
      },
      statusEntityIds: [
        if (json['statusEntityIds'] case final List<Object?> ids)
          for (final id in ids.whereType<String>().take(maxStatusEntities)) id,
      ],
    );
  }

  final bool startInKiosk;
  final bool keepScreenOn;

  /// `Duration.zero` = never.
  final Duration dimAfter;

  /// `Duration.zero` = never.
  final Duration returnHomeAfter;
  final String? pinHash;
  final String? pinSalt;

  final KioskStyle style;

  bool get bubble => style == KioskStyle.bubble;

  /// Gradient of the glass style.
  final KioskBackground background;

  /// No backdrop blur (cheaper on slow wall tablets).
  final bool liteEffects;

  /// Entities shown as chips at the top of the kiosk dashboard.
  final List<String> statusEntityIds;
  static const maxStatusEntities = 6;

  /// Camera panel on the kiosk dashboard (visible to anyone in the room).
  final bool showCameras;

  /// Calendar panel on the kiosk dashboard.
  final bool showCalendar;

  /// Own background photo (file on this device), shown instead of the
  /// gradient.
  final String? photoPath;

  /// Double clap toggles [clapTargetId] while the kiosk is shown. Opt-in:
  /// the microphone listens (levels only, nothing recorded) meanwhile.
  final bool clapEnabled;
  final String? clapTargetId;
  final ClapSensitivity clapSensitivity;

  /// A doorbell, motion or contact sensor that wakes the screen and shows
  /// [popupCameraId] full screen for [popupSeconds].
  final List<String> popupTriggerIds;
  final String? popupCameraId;
  final int popupSeconds;

  /// Live video in the pop-up when the camera offers it (else snapshots).
  final bool popupLive;
  static const popupOptions = [30, 60, 120, 300];

  bool get hasPopup => popupCameraId != null && popupTriggerIds.isNotEmpty;

  /// Lower screen brightness between [nightFrom] and [nightTo] (minutes
  /// after midnight; the window may cross midnight).
  final bool nightBrightness;
  final int nightFrom;
  final int nightTo;

  /// 0…1 of full brightness at night.
  final double nightLevel;

  /// The screensaver also turns the backlight down to its minimum.
  final bool darkScreensaver;

  /// Panels arranged on the tablet; `null` = [KioskLayout.standard].
  final KioskLayout? layout;

  KioskLayout get effectiveLayout => layout ?? KioskLayout.standard;

  static int? _minutes(Object? v) =>
      v is int && v >= 0 && v < 24 * 60 ? v : null;

  bool isNight(DateTime now) {
    final m = now.hour * 60 + now.minute;
    return nightFrom <= nightTo
        ? m >= nightFrom && m < nightTo
        : m >= nightFrom || m < nightTo;
  }

  /// Brightness the kiosk asks for; `null` = leave it to the system.
  double? brightnessAt(DateTime now, {required bool dimmed}) {
    if (dimmed && darkScreensaver) return 0.01;
    if (nightBrightness && isNight(now)) return nightLevel;
    return null;
  }

  bool get hasPin => pinHash != null && pinSalt != null;

  /// Choices offered in settings.
  static const dimOptions = [
    Duration.zero,
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 10),
  ];
  static const returnOptions = [
    Duration.zero,
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
  ];

  KioskSettings copyWith({
    bool? startInKiosk,
    bool? keepScreenOn,
    Duration? dimAfter,
    Duration? returnHomeAfter,
    String? pinHash,
    String? pinSalt,
    bool clearPin = false,
    KioskStyle? style,
    KioskBackground? background,
    bool? liteEffects,
    List<String>? statusEntityIds,
    bool? showCameras,
    bool? showCalendar,
    String? photoPath,
    bool clearPhoto = false,
    bool? clapEnabled,
    String? clapTargetId,
    ClapSensitivity? clapSensitivity,
    List<String>? popupTriggerIds,
    String? popupCameraId,
    bool clearPopupCamera = false,
    int? popupSeconds,
    bool? popupLive,
    bool? nightBrightness,
    int? nightFrom,
    int? nightTo,
    double? nightLevel,
    bool? darkScreensaver,
    KioskLayout? layout,
    bool resetLayout = false,
  }) => KioskSettings(
    layout: resetLayout ? null : (layout ?? this.layout),
    nightBrightness: nightBrightness ?? this.nightBrightness,
    nightFrom: nightFrom ?? this.nightFrom,
    nightTo: nightTo ?? this.nightTo,
    nightLevel: nightLevel ?? this.nightLevel,
    darkScreensaver: darkScreensaver ?? this.darkScreensaver,
    popupTriggerIds: popupTriggerIds ?? this.popupTriggerIds,
    popupCameraId: clearPopupCamera
        ? null
        : (popupCameraId ?? this.popupCameraId),
    popupSeconds: popupSeconds ?? this.popupSeconds,
    popupLive: popupLive ?? this.popupLive,
    clapEnabled: clapEnabled ?? this.clapEnabled,
    clapTargetId: clapTargetId ?? this.clapTargetId,
    clapSensitivity: clapSensitivity ?? this.clapSensitivity,
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    showCalendar: showCalendar ?? this.showCalendar,
    showCameras: showCameras ?? this.showCameras,
    statusEntityIds: statusEntityIds ?? this.statusEntityIds,
    style: style ?? this.style,
    background: background ?? this.background,
    liteEffects: liteEffects ?? this.liteEffects,
    startInKiosk: startInKiosk ?? this.startInKiosk,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    dimAfter: dimAfter ?? this.dimAfter,
    returnHomeAfter: returnHomeAfter ?? this.returnHomeAfter,
    pinHash: clearPin ? null : (pinHash ?? this.pinHash),
    pinSalt: clearPin ? null : (pinSalt ?? this.pinSalt),
  );

  Map<String, Object?> toJson() => {
    'startInKiosk': startInKiosk,
    'keepScreenOn': keepScreenOn,
    'dimAfterSeconds': dimAfter.inSeconds,
    'returnHomeAfterSeconds': returnHomeAfter.inSeconds,
    'pinHash': pinHash,
    'pinSalt': pinSalt,
    'style': style.name,
    'background': background.name,
    'liteEffects': liteEffects,
    'statusEntityIds': statusEntityIds,
    'showCameras': showCameras,
    'showCalendar': showCalendar,
    'photoPath': photoPath,
    'clapEnabled': clapEnabled,
    'clapTargetId': clapTargetId,
    'clapSensitivity': clapSensitivity.name,
    'popupTriggerIds': popupTriggerIds,
    'popupCameraId': popupCameraId,
    'popupSeconds': popupSeconds,
    'popupLive': popupLive,
    'nightBrightness': nightBrightness,
    'nightFrom': nightFrom,
    'nightTo': nightTo,
    'nightLevel': nightLevel,
    'darkScreensaver': darkScreensaver,
    'layout': layout?.toJson(),
  };
}
