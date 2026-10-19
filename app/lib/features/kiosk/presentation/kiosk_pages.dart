import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../application/kiosk_controller.dart';
import 'glass.dart';
import '../data/kiosk_layout.dart';
import 'kiosk_layout_view.dart';
import 'kiosk_panels.dart' show kioskNowProvider;

/// The kiosk's panels, page by page: the home layout, then the extra pages
/// (swipe left/right, dots at the bottom). After a while without a touch
/// the kiosk goes back to the home page.
class KioskPages extends ConsumerStatefulWidget {
  const KioskPages({super.key, required this.grid, this.header = const []});

  final bool grid;

  /// Shown above the home page's panels in the scrolling column.
  final List<Widget> header;

  @override
  ConsumerState<KioskPages> createState() => _KioskPagesState();
}

class _KioskPagesState extends ConsumerState<KioskPages> {
  late final PageController _controller;
  Timer? _home;
  DateTime _lastTouch = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Opening the kiosk shows the page for this time of day.
    final start = ref.read(kioskSettingsProvider).defaultPageAt(DateTime.now());
    _controller = PageController(initialPage: start);
    Future.microtask(() {
      if (mounted) ref.read(kioskPageProvider.notifier).set(start);
    });
  }

  int get _default =>
      ref.read(kioskSettingsProvider).defaultPageAt(DateTime.now());

  @override
  void dispose() {
    _home?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Duration get _idleAfter {
    final after = ref.read(kioskSettingsProvider).returnHomeAfter;
    return after > Duration.zero ? after : const Duration(minutes: 1);
  }

  /// Back to the page for this time of day (normally home) after the
  /// kiosk's "return home" time.
  void _arm() {
    _home?.cancel();
    if (ref.read(kioskPageProvider) == _default ||
        ref.read(kioskEditingProvider)) {
      return;
    }
    _home = Timer(_idleAfter, () {
      if (mounted) ref.read(kioskPageProvider.notifier).set(_default);
    });
  }

  /// A page's time window started or ended while nobody touched the panel.
  void _followSchedule() {
    if (ref.read(kioskEditingProvider)) return;
    if (DateTime.now().difference(_lastTouch) < _idleAfter) return;
    final page = _default;
    if (ref.read(kioskPageProvider) != page) {
      ref.read(kioskPageProvider.notifier).set(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = ref.watch(kioskSettingsProvider.select((s) => s.pages));
    final count = pages.length + 1;
    ref.listen(kioskNowProvider, (_, _) => _followSchedule());
    ref.listen(kioskPageProvider, (_, page) {
      _arm();
      if (!_controller.hasClients) return;
      final shown = _controller.page?.round();
      if (shown != page) {
        unawaited(
          _controller.animateToPage(
            page,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    });
    // A deleted page: stay within range.
    final current = ref.watch(kioskPageProvider);
    if (current >= count) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(kioskPageProvider.notifier).set(count - 1);
      });
    }
    if (count == 1) {
      return KioskLayoutView(grid: widget.grid, header: widget.header);
    }
    // The page view may have just appeared (first extra page added).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final page = ref.read(kioskPageProvider);
      if (_controller.page?.round() != page &&
          !_controller.position.isScrollingNotifier.value) {
        _controller.jumpToPage(page);
      }
    });
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        _lastTouch = DateTime.now();
        _arm();
      },
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              key: const Key('kioskPages'),
              controller: _controller,
              itemCount: count,
              onPageChanged: (i) => ref.read(kioskPageProvider.notifier).set(i),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return KioskLayoutView(
                    grid: widget.grid,
                    header: widget.header,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // In the column the edit bar scrolls with the home page.
                    if (!widget.grid && ref.watch(kioskEditingProvider))
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 12, 8),
                        child: KioskEditBar(),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            pages[i - 1].name,
                            key: ValueKey('kioskPageTitle-$i'),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: GlassColors.text),
                          ),
                          if (pages[i - 1].scheduled) ...[
                            const SizedBox(width: 12),
                            Text(
                              kioskPageWindow(pages[i - 1]),
                              key: ValueKey('kioskPageWindow-$i'),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(color: GlassColors.muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: KioskLayoutView(grid: widget.grid, page: i),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < count; i++)
                Semantics(
                  button: true,
                  label: i == 0 ? l10n.kioskHomePage : pages[i - 1].name,
                  selected: i == current,
                  child: GestureDetector(
                    key: ValueKey('kioskPageDot-$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => ref.read(kioskPageProvider.notifier).set(i),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == current ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == current
                              ? GlassColors.text
                              : GlassColors.faint,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "19:00–23:00".
String kioskPageWindow(KioskPage p) {
  String hm(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  return '${hm(p.from!)}–${hm(p.to!)}';
}
