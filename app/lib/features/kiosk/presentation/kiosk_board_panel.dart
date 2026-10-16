import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../board/board_canvas.dart';
import '../../board/board_page.dart';
import '../../board/board_repository.dart';
import 'glass.dart';

/// The family board on the wall panel: the most recent page; tap to write
/// or draw on it, "+" for a new page.
class KioskBoardPanel extends ConsumerWidget {
  const KioskBoardPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pages = ref.watch(boardPagesProvider).value ?? const [];
    final latest = pages.firstOrNull;
    final content = latest == null
        ? null
        : ref.watch(boardContentProvider(latest)).value;
    void open(String pageId) =>
        context.push(AppRoutes.board(pageId, kiosk: true));

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassTitle(
            l10n.boardTitle,
            trailing: IconButton.filledTonal(
              key: const Key('kioskBoardNew'),
              tooltip: l10n.boardNewPage,
              onPressed: () => open(BoardRepository.newPageId()),
              icon: const Icon(Icons.add),
            ),
          ),
          Expanded(
            child: GestureDetector(
              key: const Key('kioskBoardOpen'),
              onTap: () => open(latest?.pageId ?? BoardRepository.newPageId()),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: latest == null
                    ? ColoredBox(
                        color: GlassColors.fill,
                        child: Center(
                          child: Icon(
                            Icons.draw_outlined,
                            size: 48,
                            color: GlassColors.muted,
                            semanticLabel: l10n.boardNewPage,
                          ),
                        ),
                      )
                    : FittedBox(
                        child: SizedBox(
                          width: boardWidth / 2,
                          height: boardHeight / 2,
                          child: CustomPaint(
                            painter: BoardPainter(
                              strokes: content?.strokes ?? const [],
                              dark: false,
                              dots: false,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
