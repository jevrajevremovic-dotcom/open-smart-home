import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time application configuration.
///
/// Mock mode is requested with `--dart-define=SMARTHOME_MOCK=true` and is
/// **always disabled in release builds**, so mock data can never ship to
/// production by accident.
@immutable
class AppConfig {
  const AppConfig({required this.mockMode});

  factory AppConfig.fromEnvironment() =>
      const AppConfig(mockMode: _mockRequested && !kReleaseMode);

  static const bool _mockRequested = bool.fromEnvironment('SMARTHOME_MOCK');

  final bool mockMode;

  /// Built for an app store (`--dart-define=STORE_BUILD=true`, see
  /// `tool/build_play.sh`): the store updates the app, so it never
  /// downloads or installs updates itself.
  static const bool storeBuild = bool.fromEnvironment('STORE_BUILD');

  /// Timeouts for REST calls against Home Assistant.
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// WebSocket heartbeat (HA `ping`/`pong`) and per-command timeout.
  static const Duration webSocketPingInterval = Duration(seconds: 30);
  static const Duration webSocketCommandTimeout = Duration(seconds: 10);
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
