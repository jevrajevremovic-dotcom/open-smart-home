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

/// Accent family of a device: the colour its tile takes when it is on.
enum DeviceAccent { light, cool, heat, power, media, motion }

/// One accent family: the tile fill when active, the text on it, and the
/// icon colour (shown on a white/translucent disc).
@immutable
class AccentSwatch {
  const AccentSwatch(this.container, this.onContainer, this.icon);

  final Color container;
  final Color onContainer;
  final Color icon;

  static AccentSwatch lerp(AccentSwatch a, AccentSwatch b, double t) =>
      AccentSwatch(
        Color.lerp(a.container, b.container, t)!,
        Color.lerp(a.onContainer, b.onContainer, t)!,
        Color.lerp(a.icon, b.icon, t)!,
      );
}

/// Warm, soft tile colours per [DeviceAccent], plus warning and critical
/// fills. Every pair keeps at least 4.5:1 contrast for text.
@immutable
class DeviceAccents extends ThemeExtension<DeviceAccents> {
  const DeviceAccents({
    required this.swatches,
    required this.warning,
    required this.critical,
    required this.iconDisc,
  });

  static const light = DeviceAccents(
    swatches: {
      DeviceAccent.light: AccentSwatch(
        Color(0xFFFFD98A),
        Color(0xFF4A3305),
        Color(0xFFB07A0E),
      ),
      DeviceAccent.cool: AccentSwatch(
        Color(0xFFCFE6FF),
        Color(0xFF0C3A63),
        Color(0xFF1F6BB0),
      ),
      DeviceAccent.heat: AccentSwatch(
        Color(0xFFFFD3C2),
        Color(0xFF5A1E08),
        Color(0xFFC2410C),
      ),
      DeviceAccent.power: AccentSwatch(
        Color(0xFFCDEFD9),
        Color(0xFF0E4024),
        Color(0xFF1E8E4A),
      ),
      DeviceAccent.media: AccentSwatch(
        Color(0xFFE3DAFF),
        Color(0xFF2E1F6B),
        Color(0xFF5B45C4),
      ),
      DeviceAccent.motion: AccentSwatch(
        Color(0xFFD3EEF0),
        Color(0xFF0F4146),
        Color(0xFF1A7F88),
      ),
    },
    warning: AccentSwatch(
      Color(0xFFFFE4BC),
      Color(0xFF5A3300),
      Color(0xFFB45F06),
    ),
    critical: AccentSwatch(
      Color(0xFFFFD9D4),
      Color(0xFF6B0F0A),
      Color(0xFFBA1A1A),
    ),
    iconDisc: Color(0xFFFFFFFF),
  );

  static const dark = DeviceAccents(
    swatches: {
      DeviceAccent.light: AccentSwatch(
        Color(0xFF4A3610),
        Color(0xFFFFE2A8),
        Color(0xFFFFC861),
      ),
      DeviceAccent.cool: AccentSwatch(
        Color(0xFF173552),
        Color(0xFFCFE6FF),
        Color(0xFF8CC8FF),
      ),
      DeviceAccent.heat: AccentSwatch(
        Color(0xFF4F2414),
        Color(0xFFFFD3C2),
        Color(0xFFFF9C73),
      ),
      DeviceAccent.power: AccentSwatch(
        Color(0xFF173D27),
        Color(0xFFC8F0D6),
        Color(0xFF7EDB98),
      ),
      DeviceAccent.media: AccentSwatch(
        Color(0xFF2E2752),
        Color(0xFFE3DAFF),
        Color(0xFFB9A8FF),
      ),
      DeviceAccent.motion: AccentSwatch(
        Color(0xFF173D41),
        Color(0xFFCDEFF1),
        Color(0xFF7FD3DB),
      ),
    },
    warning: AccentSwatch(
      Color(0xFF4A3008),
      Color(0xFFFFDDAA),
      Color(0xFFFFB870),
    ),
    critical: AccentSwatch(
      Color(0xFF5A1A16),
      Color(0xFFFFDAD5),
      Color(0xFFFFB4AB),
    ),
    iconDisc: Color(0x1FFFFFFF),
  );

  final Map<DeviceAccent, AccentSwatch> swatches;
  final AccentSwatch warning;
  final AccentSwatch critical;

  /// Background of the round icon badge on a tile.
  final Color iconDisc;

  AccentSwatch of(DeviceAccent accent) => swatches[accent]!;

  @override
  DeviceAccents copyWith({
    Map<DeviceAccent, AccentSwatch>? swatches,
    AccentSwatch? warning,
    AccentSwatch? critical,
    Color? iconDisc,
  }) => DeviceAccents(
    swatches: swatches ?? this.swatches,
    warning: warning ?? this.warning,
    critical: critical ?? this.critical,
    iconDisc: iconDisc ?? this.iconDisc,
  );

  @override
  DeviceAccents lerp(DeviceAccents? other, double t) {
    if (other == null) return this;
    return DeviceAccents(
      swatches: {
        for (final a in DeviceAccent.values)
          a: AccentSwatch.lerp(of(a), other.of(a), t),
      },
      warning: AccentSwatch.lerp(warning, other.warning, t),
      critical: AccentSwatch.lerp(critical, other.critical, t),
      iconDisc: Color.lerp(iconDisc, other.iconDisc, t)!,
    );
  }
}

extension DeviceAccentsX on BuildContext {
  DeviceAccents get deviceAccents =>
      Theme.of(this).extension<DeviceAccents>() ?? DeviceAccents.light;
}

/// "Warm minimal" look: a soft warm canvas, white rounded cards without
/// borders or shadows, pill-shaped controls and coloured tiles for devices
/// that are on.
abstract final class AppTheme {
  /// Minimum touch target; larger than Material's 48 dp because the app is
  /// also used on wall-mounted tablets.
  static const double minTouchTarget = 52;

  /// Corner radius of cards and tiles.
  static const double cardRadius = 24;

  static ThemeData light() =>
      _build(_lightScheme, StatusColors.light, DeviceAccents.light);
  static ThemeData dark() =>
      _build(_darkScheme, StatusColors.dark, DeviceAccents.dark);

  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFB5521B),
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFFA94C17),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFFFE2CC),
        onPrimaryContainer: const Color(0xFF4A2006),
        secondaryContainer: const Color(0xFFF1E4D6),
        onSecondaryContainer: const Color(0xFF3B2E22),
        surface: const Color(0xFFF5F1EB),
        onSurface: const Color(0xFF26221E),
        onSurfaceVariant: const Color(0xFF6B6258),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Colors.white,
        surfaceContainer: const Color(0xFFEFEAE3),
        surfaceContainerHigh: const Color(0xFFE9E3DB),
        surfaceContainerHighest: const Color(0xFFE2DBD1),
        outline: const Color(0xFF9C9286),
        outlineVariant: const Color(0xFFE2DBD1),
      );

  static final ColorScheme _darkScheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFB5521B),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFFFB27A),
        onPrimary: const Color(0xFF4A2006),
        primaryContainer: const Color(0xFF6B3412),
        onPrimaryContainer: const Color(0xFFFFDCC4),
        secondaryContainer: const Color(0xFF3A3129),
        onSecondaryContainer: const Color(0xFFF1E4D6),
        surface: const Color(0xFF14120F),
        onSurface: const Color(0xFFF1ECE5),
        onSurfaceVariant: const Color(0xFFB8AEA2),
        surfaceContainerLowest: const Color(0xFF0F0D0B),
        surfaceContainerLow: const Color(0xFF211D19),
        surfaceContainer: const Color(0xFF2A2621),
        surfaceContainerHigh: const Color(0xFF332E29),
        surfaceContainerHighest: const Color(0xFF3D3731),
        outline: const Color(0xFF857B70),
        outlineVariant: const Color(0xFF3A342E),
      );

  static ThemeData _build(
    ColorScheme scheme,
    StatusColors status,
    DeviceAccents accents,
  ) {
    const buttonSize = Size(64, minTouchTarget);
    const pill = StadiumBorder();
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme).textTheme;
    TextStyle? tight(TextStyle? s, FontWeight w, [double spacing = -0.2]) =>
        s?.copyWith(fontWeight: w, letterSpacing: spacing);
    final text = base.copyWith(
      displaySmall: tight(base.displaySmall, FontWeight.w600, -0.8),
      headlineLarge: tight(base.headlineLarge, FontWeight.w600, -0.6),
      headlineMedium: tight(base.headlineMedium, FontWeight.w600, -0.5),
      headlineSmall: tight(base.headlineSmall, FontWeight.w600, -0.4),
      titleLarge: tight(base.titleLarge, FontWeight.w600, -0.3),
      titleMedium: tight(base.titleMedium, FontWeight.w600),
      titleSmall: tight(base.titleSmall, FontWeight.w600, -0.1),
      labelLarge: tight(base.labelLarge, FontWeight.w600, 0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      extensions: [status, accents],
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: pill,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: pill,
        selectedLabelTextStyle: text.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: pill,
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: buttonSize, shape: pill),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: pill,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, minTouchTarget),
          shape: pill,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          side: BorderSide(color: scheme.outlineVariant),
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.transparent
              : scheme.outline,
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 10,
        inactiveTrackColor: scheme.surfaceContainerHighest,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
