import 'package:flutter/material.dart';

/// Semantic status colours used consistently across the app. Always pair
/// them with an icon or text — colour alone must never carry meaning.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.ok,
    required this.onOk,
    required this.warning,
    required this.onWarning,
    required this.critical,
    required this.onCritical,
    required this.unavailable,
    required this.onUnavailable,
  });

  static const light = StatusColors(
    ok: Color(0xFF1B7F3B),
    onOk: Colors.white,
    warning: Color(0xFFB45F06),
    onWarning: Colors.white,
    critical: Color(0xFFBA1A1A),
    onCritical: Colors.white,
    unavailable: Color(0xFF6F7975),
    onUnavailable: Colors.white,
  );

  static const dark = StatusColors(
    ok: Color(0xFF7EDB98),
    onOk: Color(0xFF00391A),
    warning: Color(0xFFFFB870),
    onWarning: Color(0xFF4A2800),
    critical: Color(0xFFFFB4AB),
    onCritical: Color(0xFF690005),
    unavailable: Color(0xFFA9B3AE),
    onUnavailable: Color(0xFF1B2421),
  );

  final Color ok;
  final Color onOk;
  final Color warning;
  final Color onWarning;
  final Color critical;
  final Color onCritical;
  final Color unavailable;
  final Color onUnavailable;

  @override
  StatusColors copyWith({
    Color? ok,
    Color? onOk,
    Color? warning,
    Color? onWarning,
    Color? critical,
    Color? onCritical,
    Color? unavailable,
    Color? onUnavailable,
  }) => StatusColors(
    ok: ok ?? this.ok,
    onOk: onOk ?? this.onOk,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    critical: critical ?? this.critical,
    onCritical: onCritical ?? this.onCritical,
    unavailable: unavailable ?? this.unavailable,
    onUnavailable: onUnavailable ?? this.onUnavailable,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      ok: Color.lerp(ok, other.ok, t)!,
      onOk: Color.lerp(onOk, other.onOk, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      onCritical: Color.lerp(onCritical, other.onCritical, t)!,
      unavailable: Color.lerp(unavailable, other.unavailable, t)!,
      onUnavailable: Color.lerp(onUnavailable, other.onUnavailable, t)!,
    );
  }
}

extension StatusColorsX on BuildContext {
  StatusColors get statusColors =>
      Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
}

abstract final class AppTheme {
  static const Color _seed = Color(0xFF00897B);

  /// Minimum touch target; larger than Material's 48 dp because the app is
  /// also used on wall-mounted tablets.
  static const double minTouchTarget = 52;

  static ThemeData light() => _build(Brightness.light, StatusColors.light);
  static ThemeData dark() => _build(Brightness.dark, StatusColors.dark);

  static ThemeData _build(Brightness brightness, StatusColors status) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    const buttonSize = Size(64, minTouchTarget);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [status],
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: buttonSize),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: buttonSize),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, minTouchTarget),
        ),
      ),
      cardTheme: const CardThemeData(margin: EdgeInsets.zero),
    );
  }
}
