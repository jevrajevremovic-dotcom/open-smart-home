import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/kiosk_controller.dart';
import '../data/kiosk_photo.dart';
import '../data/kiosk_settings.dart';

/// Colours of one kiosk background: a diagonal base gradient and two soft
/// glows. All variants are dark, so white text stays readable on the glass.
@immutable
class KioskPalette {
  const KioskPalette(this.base, this.glowA, this.glowB);

  final List<Color> base;
  final Color glowA;
  final Color glowB;

  static KioskPalette of(KioskBackground b) => switch (b) {
    KioskBackground.aurora => const KioskPalette(
      [
        Color(0xFF0A1035),
        Color(0xFF18287A),
        Color(0xFF1B4F86),
        Color(0xFF0F6B63),
      ],
      Color(0xFF3F6BFF),
      Color(0xFF1FB89A),
    ),
    KioskBackground.ocean => const KioskPalette(
      [Color(0xFF03142A), Color(0xFF0A355A), Color(0xFF0D5C73)],
      Color(0xFF2D9CDB),
      Color(0xFF3FC1C9),
    ),
    KioskBackground.dusk => const KioskPalette(
      [
        Color(0xFF170D2B),
        Color(0xFF41205A),
        Color(0xFF7E3157),
        Color(0xFF9C4B3C),
      ],
      Color(0xFFFF8A5B),
      Color(0xFF8E44AD),
    ),
    KioskBackground.forest => const KioskPalette(
      [Color(0xFF06150E), Color(0xFF103326), Color(0xFF285539)],
      Color(0xFF4FBF83),
      Color(0xFFC9A24A),
    ),
  };
}

final kioskPhotoStoreProvider = Provider<KioskPhotoStore>(
  (ref) => PlatformKioskPhotoStore(),
);

/// Full-screen gradient with two blurred light spots behind the panels.
class KioskBackdrop extends ConsumerWidget {
  const KioskBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = KioskPalette.of(
      ref.watch(kioskSettingsProvider.select((s) => s.background)),
    );
    final photoPath = ref.watch(
      kioskSettingsProvider.select((s) => s.photoPath),
    );
    final photo = photoPath == null
        ? null
        : ref.watch(kioskPhotoStoreProvider).image(photoPath);
    if (photo != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(image: photo, fit: BoxFit.cover),
        ),
        // Darkened so white text stays readable on any photo.
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x99000000), Color(0x73000000), Color(0xB3000000)],
            ),
          ),
          child: child,
        ),
      );
    }
    Widget glow(Color color, Alignment at, double size) => Align(
      alignment: at,
      child: FractionallySizedBox(
        widthFactor: size,
        heightFactor: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.45),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.base,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: glow(palette.glowA, const Alignment(-0.9, -0.8), 1.1),
          ),
          IgnorePointer(
            child: glow(palette.glowB, const Alignment(1, 0.9), 1.2),
          ),
          child,
        ],
      ),
    );
  }
}

/// Text and icon colours on glass.
abstract final class GlassColors {
  static const Color text = Colors.white;
  static const Color muted = Color(0xC7FFFFFF); // 78 %
  static const Color faint = Color(0x8AFFFFFF); // 54 %
  static const Color fill = Color(0x1AFFFFFF);
  static const Color fillStrong = Color(0x2EFFFFFF);
  static const Color border = Color(0x29FFFFFF);
}

/// Frosted-glass panel. Without blur in "lighter effects" mode.
class GlassPanel extends ConsumerWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lite = ref.watch(kioskSettingsProvider.select((s) => s.liteEffects));
    final shape = BorderRadius.circular(radius);
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        border: Border.all(color: GlassColors.border),
        gradient: color == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: lite ? 0.16 : 0.14),
                  Colors.white.withValues(alpha: lite ? 0.08 : 0.05),
                ],
              )
            : null,
        color: color,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (lite) return panel;
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: panel,
      ),
    );
  }
}

/// Panel heading in the glass style.
class GlassTitle extends StatelessWidget {
  const GlassTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: GlassColors.text),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
