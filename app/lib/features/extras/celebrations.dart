import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/app_preferences.dart';
import '../kiosk/application/kiosk_now.dart';
import '../kiosk/application/kiosk_people.dart';
import '../kiosk/presentation/kiosk_motion.dart';

/// What falls across the wall panel.
enum Celebration { snow, confetti, halloween }

/// The season's decoration for [day], if any: snow from December to
/// Orthodox Christmas, confetti for New Year's Eve and Day, pumpkins the
/// week before Halloween.
Celebration? seasonFor(DateTime day) {
  final md = day.month * 100 + day.day;
  if (md == 1231 || md == 101) return Celebration.confetti;
  if (md >= 1201 || md <= 107) return Celebration.snow;
  if (md >= 1024 && md <= 1031) return Celebration.halloween;
  return null;
}

/// Household members whose birthday is today (set per member on the
/// wall panel).
final birthdaysTodayProvider = Provider<List<String>>((ref) {
  final now = ref.watch(kioskNowProvider);
  return [
    for (final e in ref.watch(kioskPeopleProvider).entries)
      if (e.value.birthday case (final m, final d)
          when m == now.month && d == now.day)
        e.key,
  ];
});

/// Seasonal decorations on the wall panel (on by default).
class SeasonalController extends Notifier<bool> {
  static const _key = 'kiosk.seasonal';

  @override
  bool build() =>
      ref.watch(appPreferencesProvider).readJson(_key)?['enabled'] != false;

  Future<void> set(bool enabled) async {
    state = enabled;
    await ref
        .read(appPreferencesProvider)
        .writeJson(_key, enabled ? null : {'enabled': false});
  }
}

final seasonalProvider = NotifierProvider<SeasonalController, bool>(
  SeasonalController.new,
);

/// Today's celebration: a birthday's confetti first, then the season's.
final celebrationProvider = Provider<Celebration?>((ref) {
  if (!ref.watch(seasonalProvider)) return null;
  if (ref.watch(birthdaysTodayProvider).isNotEmpty) {
    return Celebration.confetti;
  }
  return seasonFor(ref.watch(kioskNowProvider));
});

/// Falling snow, confetti or pumpkins over the wall panel; never in the
/// way of a tap, still when the screen is dimmed or motion is reduced.
class CelebrationLayer extends ConsumerStatefulWidget {
  const CelebrationLayer({super.key});

  @override
  ConsumerState<CelebrationLayer> createState() => _CelebrationLayerState();
}

class _CelebrationLayerState extends ConsumerState<CelebrationLayer>
    with SingleTickerProviderStateMixin {
  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(
    (elapsed) => _time.value = elapsed.inMicroseconds / 1e6,
  );

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = ref.watch(celebrationProvider);
    final moving = kioskMotion(context, ref);
    final run = kind != null && moving;
    if (run && !_ticker.isActive) _ticker.start();
    if (!run && _ticker.isActive) _ticker.stop();
    if (!run) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          key: ValueKey('celebration-${kind.name}'),
          size: Size.infinite,
          painter: _FallPainter(kind, _time),
        ),
      ),
    );
  }
}

/// Everything is a function of time: no per-frame state to keep.
class _FallPainter extends CustomPainter {
  _FallPainter(this.kind, this.time) : super(repaint: time);

  final Celebration kind;
  final ValueNotifier<double> time;

  static final _random = math.Random(7);
  static final _seeds = List.generate(
    70,
    (_) => [for (var i = 0; i < 5; i++) _random.nextDouble()],
  );
  static const _confetti = [
    Color(0xFFFF5A5F),
    Color(0xFFFFC233),
    Color(0xFF3D7BFF),
    Color(0xFF2DBE6C),
    Color(0xFFB065E8),
  ];
  static const _spooky = ['🎃', '🍂', '🦇', '🍁'];
  final _glyphs = <String, TextPainter>{};

  int get _count => switch (kind) {
    Celebration.snow => 55,
    Celebration.confetti => 70,
    Celebration.halloween => 14,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final s = _seeds[i];
      // Seconds to cross the screen, and where along it this one is.
      final crossing = switch (kind) {
        Celebration.snow => 14 + 10 * s[0],
        Celebration.confetti => 7 + 5 * s[0],
        Celebration.halloween => 22 + 12 * s[0],
      };
      final y = ((s[1] + t / crossing) % 1) * (size.height + 60) - 30;
      final sway = math.sin(t * (0.6 + s[2]) + s[3] * 6.3) * 24;
      final x = s[4] * size.width + sway;
      switch (kind) {
        case Celebration.snow:
          paint.color = Colors.white.withValues(alpha: 0.35 + 0.4 * s[2]);
          canvas.drawCircle(Offset(x, y), 1.5 + 3 * s[3], paint);
        case Celebration.confetti:
          paint.color = _confetti[i % _confetti.length].withValues(alpha: 0.8);
          canvas
            ..save()
            ..translate(x, y)
            ..rotate(t * (1 + 3 * s[2]) + s[3] * 6.3)
            ..drawRect(const Rect.fromLTWH(-4, -2, 8, 4), paint)
            ..restore();
        case Celebration.halloween:
          final glyph = _spooky[i % _spooky.length];
          final tp = _glyphs[glyph] ??= TextPainter(
            text: TextSpan(text: glyph, style: const TextStyle(fontSize: 28)),
            textDirection: TextDirection.ltr,
          )..layout();
          canvas
            ..save()
            ..translate(x, y)
            ..rotate(math.sin(t + s[3] * 6) * 0.4);
          tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
          canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_FallPainter old) => old.kind != kind;
}
