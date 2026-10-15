import 'package:flutter/foundation.dart';

import '../../clap/clap_detector.dart';

/// Gradient behind the kiosk dashboard's glass panels.
enum KioskBackground { aurora, ocean, dusk, forest }

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
    this.background = KioskBackground.aurora,
    this.liteEffects = false,
    this.statusEntityIds = const [],
    this.showCameras = true,
    this.showCalendar = true,
    this.photoPath,
    this.clapEnabled = false,
    this.clapTargetId,
    this.clapSensitivity = ClapSensitivity.medium,
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
  }) => KioskSettings(
    clapEnabled: clapEnabled ?? this.clapEnabled,
    clapTargetId: clapTargetId ?? this.clapTargetId,
    clapSensitivity: clapSensitivity ?? this.clapSensitivity,
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    showCalendar: showCalendar ?? this.showCalendar,
    showCameras: showCameras ?? this.showCameras,
    statusEntityIds: statusEntityIds ?? this.statusEntityIds,
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
    'background': background.name,
    'liteEffects': liteEffects,
    'statusEntityIds': statusEntityIds,
    'showCameras': showCameras,
    'showCalendar': showCalendar,
    'photoPath': photoPath,
    'clapEnabled': clapEnabled,
    'clapTargetId': clapTargetId,
    'clapSensitivity': clapSensitivity.name,
  };
}
