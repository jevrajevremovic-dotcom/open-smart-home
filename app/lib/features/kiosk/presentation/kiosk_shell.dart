import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../application/kiosk_controller.dart';
import 'camera_popup.dart';

/// Wraps every kiosk route: fullscreen, screen kept on, back button
/// blocked, return to the kiosk dashboard and dimming after inactivity.
class KioskShell extends ConsumerStatefulWidget {
  const KioskShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  ConsumerState<KioskShell> createState() => _KioskShellState();
}

class _KioskShellState extends ConsumerState<KioskShell> {
  Timer? _returnTimer;
  Timer? _dimTimer;
  bool _dimmed = false;
  late final KioskPlatform _platform = ref.read(kioskPlatformProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_platform.enterFullscreen());
    unawaited(
      _platform.keepScreenOn(ref.read(kioskSettingsProvider).keepScreenOn),
    );
    _restartTimers();
  }

  @override
  void dispose() {
    _returnTimer?.cancel();
    _dimTimer?.cancel();
    unawaited(_platform.exitFullscreen());
    unawaited(_platform.keepScreenOn(false));
    super.dispose();
  }

  @override
  void didUpdateWidget(KioskShell old) {
    super.didUpdateWidget(old);
    if (old.location != widget.location) _restartTimers();
  }

  void _setDimmed(bool dimmed) {
    setState(() => _dimmed = dimmed);
    ref.read(kioskDimmedProvider.notifier).set(dimmed);
  }

  void _onInteraction() {
    if (_dimmed) _setDimmed(false);
    _restartTimers();
  }

  void _restartTimers() {
    final settings = ref.read(kioskSettingsProvider);
    _returnTimer?.cancel();
    _dimTimer?.cancel();
    if (settings.returnHomeAfter > Duration.zero &&
        widget.location != AppRoutes.kiosk) {
      _returnTimer = Timer(settings.returnHomeAfter, () {
        if (mounted) context.go(AppRoutes.kiosk);
      });
    }
    if (settings.dimAfter > Duration.zero) {
      _dimTimer = Timer(settings.dimAfter, () {
        if (mounted) _setDimmed(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(kioskSettingsProvider, (_, next) {
      unawaited(_platform.keepScreenOn(next.keepScreenOn));
      _restartTimers();
    });
    return PopScope(
      // Android back may only navigate within kiosk, never out of it.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.location != AppRoutes.kiosk) {
          context.go(AppRoutes.kiosk);
        }
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _onInteraction(),
        child: KioskCameraPopup(
          onShow: _onInteraction,
          child: Stack(
            children: [
              widget.child,
              if (_dimmed)
                Positioned.fill(child: _Screensaver(onWake: _onInteraction)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark overlay with a clock. Absorbs the waking tap so it does not also
/// press whatever control is underneath.
class _Screensaver extends StatelessWidget {
  const _Screensaver({required this.onWake});

  final VoidCallback onWake;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const Key('kioskScreensaver'),
    behavior: HitTestBehavior.opaque,
    onTap: onWake,
    child: ColoredBox(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KioskClock(large: true, color: Colors.white70),
            const SizedBox(height: 24),
            Text(
              context.l10n.kioskTapToWake,
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Time and date, refreshed at each minute boundary.
class KioskClock extends StatefulWidget {
  const KioskClock({super.key, this.large = false, this.color});

  final bool large;
  final Color? color;

  @override
  State<KioskClock> createState() => _KioskClockState();
}

class _KioskClockState extends State<KioskClock> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    _timer = Timer(nextMinute.difference(now), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.onSurface;
    return Semantics(
      liveRegion: false,
      child: Column(
        crossAxisAlignment: widget.large
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat.Hm(locale).format(_now),
            style:
                (widget.large
                        ? theme.textTheme.displayLarge
                        : theme.textTheme.displaySmall)
                    ?.copyWith(color: color, fontWeight: FontWeight.w300),
          ),
          Text(
            DateFormat.MMMMEEEEd(locale).format(_now),
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
