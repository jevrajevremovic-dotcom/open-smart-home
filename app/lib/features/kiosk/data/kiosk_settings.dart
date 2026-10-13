import 'package:flutter/foundation.dart';

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
  }) => KioskSettings(
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
  };
}
