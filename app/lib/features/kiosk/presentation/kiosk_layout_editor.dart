part of 'kiosk_layout_view.dart';

/// A panel while editing: long press and drag to move it onto another
/// panel; buttons change size, order and content.
class _EditablePanel extends ConsumerWidget {
  const _EditablePanel({
    required this.panel,
    required this.layout,
    required this.page,
    required this.grid,
    required this.child,
  });

  final KioskPanel panel;
  final KioskLayout layout;
  final int page;
  final bool grid;
  final Widget child;

  void _save(WidgetRef ref, KioskLayout next) => ref
      .read(kioskSettingsProvider.notifier)
      .update((s) => s.withLayoutOf(page, next));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final index = layout.panels.indexWhere((p) => p.id == panel.id);
    final label = kioskPanelLabel(l10n, panel.type);

    Widget button(String key, IconData icon, String tip, VoidCallback? on) =>
        IconButton.filledTonal(
          key: ValueKey('$key-${panel.id}'),
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          onPressed: on,
          icon: Icon(icon),
        );

    Widget body(bool target) => Stack(
      fit: StackFit.passthrough,
      children: [
        // Editing, not using: taps go to the controls only.
        IgnorePointer(child: child),
        // Catches the long press that starts a drag anywhere on the panel.
        const Positioned.fill(child: ColoredBox(color: Colors.transparent)),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.black.withValues(alpha: target ? 0.35 : 0.6),
                border: Border.all(
                  color: target ? Colors.amber : Colors.white54,
                  width: target ? 3 : 1.5,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          // One row that shrinks on narrow panels instead of wrapping.
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      button(
                        'kioskPanelEarlier',
                        Icons.chevron_left,
                        l10n.kioskPanelEarlier,
                        index <= 0
                            ? null
                            : () => _save(
                                ref,
                                layout.move(
                                  panel.id,
                                  layout.panels[index - 1].id,
                                  after: false,
                                ),
                              ),
                      ),
                      button(
                        'kioskPanelLater',
                        Icons.chevron_right,
                        l10n.kioskPanelLater,
                        index >= layout.panels.length - 1
                            ? null
                            : () => _save(
                                ref,
                                layout.move(
                                  panel.id,
                                  layout.panels[index + 1].id,
                                  after: true,
                                ),
                              ),
                      ),
                      button(
                        'kioskPanelNarrower',
                        Icons.remove,
                        l10n.kioskPanelNarrower,
                        panel.span <= KioskLayout.minSpan
                            ? null
                            : () => _save(ref, layout.resize(panel.id, -1)),
                      ),
                      button(
                        'kioskPanelWider',
                        Icons.add,
                        l10n.kioskPanelWider,
                        panel.span >= 12
                            ? null
                            : () => _save(ref, layout.resize(panel.id, 1)),
                      ),
                      button(
                        'kioskPanelHeight',
                        panel.height == 1
                            ? Icons.unfold_more
                            : Icons.unfold_less,
                        l10n.kioskPanelHeight,
                        () => _save(ref, layout.toggleHeight(panel.id)),
                      ),
                      if (panel.type.usesEntity)
                        button(
                          'kioskPanelDevice',
                          Icons.tune,
                          l10n.kioskPanelChooseDevice,
                          () async {
                            final id = await pickKioskPanelDevice(
                              context,
                              panel.type,
                            );
                            if (id != null) {
                              _save(
                                ref,
                                layout.update(
                                  panel.id,
                                  (p) => p.copyWith(entityId: id),
                                ),
                              );
                            }
                          },
                        ),
                      button(
                        'kioskPanelRemove',
                        Icons.close,
                        l10n.kioskPanelRemove,
                        () => _save(ref, layout.remove(panel.id)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 10,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.drag_indicator, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      grid ? '$label · ${panel.span}/12' : label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != panel.id,
      onAcceptWithDetails: (d) {
        final box = context.findRenderObject() as RenderBox?;
        var after = true;
        if (box != null) {
          // The drop point: the middle of the dragged card.
          final local = box.globalToLocal(d.offset + const Offset(80, 50));
          after = grid
              ? local.dx > box.size.width / 2
              : local.dy > box.size.height / 2;
        }
        _save(ref, layout.move(d.data, panel.id, after: after));
      },
      builder: (context, candidates, _) => LongPressDraggable<String>(
        key: ValueKey('kioskPanel-${panel.id}'),
        data: panel.id,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.85,
            child: SizedBox(
              width: 160,
              height: 100,
              child: GlassPanel(
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: body(false)),
        child: body(candidates.isNotEmpty),
      ),
    );
  }
}

/// Picks the device for a thermostat or device panel.
Future<String?> pickKioskPanelDevice(
  BuildContext context,
  KioskPanelType type,
) => showDialog<String>(
  context: context,
  builder: (_) => _DevicePickerDialog(type: type),
);

class _DevicePickerDialog extends ConsumerStatefulWidget {
  const _DevicePickerDialog({required this.type});

  final KioskPanelType type;

  @override
  ConsumerState<_DevicePickerDialog> createState() =>
      _DevicePickerDialogState();
}

class _DevicePickerDialogState extends ConsumerState<_DevicePickerDialog> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
    final list =
        devices.values
            .where(
              (d) =>
                  !d.isAuxiliary &&
                  d.kind != DeviceKind.unknown &&
                  (widget.type != KioskPanelType.thermostat ||
                      d.kind == DeviceKind.climate ||
                      d.kind == DeviceKind.thermostat) &&
                  (widget.type == KioskPanelType.lists) ==
                      (d.kind == DeviceKind.todoList) &&
                  (widget.type != KioskPanelType.media ||
                      d.kind == DeviceKind.mediaPlayer ||
                      d.kind == DeviceKind.speaker ||
                      d.kind == DeviceKind.television) &&
                  d.name.toLowerCase().contains(_q.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return AlertDialog(
      title: Text(l10n.kioskPanelChooseDevice),
      content: SizedBox(
        width: 440,
        height: 460,
        child: Column(
          children: [
            TextField(
              key: const Key('kioskPanelSearch'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchHint,
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final d in list)
                    ListTile(
                      key: ValueKey('kioskPick-${d.id}'),
                      leading: Icon(DevicePresentation.icon(d)),
                      title: Text(d.name),
                      onTap: () => Navigator.of(context).pop(d.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

/// Replaces the header while editing.
class KioskEditBar extends ConsumerWidget {
  const KioskEditBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(kioskSettingsProvider.notifier);
    final page = ref.watch(kioskPageProvider);
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.dashboard_customize_outlined, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.kioskEditHint,
              style: const TextStyle(color: GlassColors.text),
            ),
          ),
          TextButton.icon(
            key: const Key('kioskAddPanel'),
            onPressed: () async {
              final type = await showDialog<KioskPanelType>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: Text(l10n.kioskAddPanel),
                  children: [
                    for (final t in KioskPanelType.values)
                      SimpleDialogOption(
                        key: ValueKey('kioskAdd-${t.name}'),
                        onPressed: () => Navigator.of(context).pop(t),
                        child: Text(kioskPanelLabel(l10n, t)),
                      ),
                  ],
                ),
              );
              if (type == null || !context.mounted) return;
              String? entity;
              if (type == KioskPanelType.device) {
                entity = await pickKioskPanelDevice(context, type);
                if (entity == null) return;
              }
              final page = ref.read(kioskPageProvider);
              await settings.update(
                (s) => s.withLayoutOf(
                  page,
                  s.layoutOf(page).add(type, entityId: entity),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.kioskAddPanel),
          ),
          TextButton.icon(
            key: const Key('kioskAddPage'),
            onPressed: () => addKioskPage(context, ref),
            icon: const Icon(Icons.add_to_photos_outlined),
            label: Text(l10n.kioskAddPage),
          ),
          if (page == 0)
            TextButton(
              key: const Key('kioskLayoutReset'),
              onPressed: () =>
                  settings.update((s) => s.copyWith(resetLayout: true)),
              child: Text(l10n.dashLayoutReset),
            )
          else ...[
            TextButton(
              key: const Key('kioskPageSchedule'),
              onPressed: () => scheduleKioskPage(context, ref, page),
              child: Text(l10n.kioskPageSchedule),
            ),
            TextButton(
              key: const Key('kioskRenamePage'),
              onPressed: () => renameKioskPage(context, ref, page),
              child: Text(l10n.kioskRenamePage),
            ),
            TextButton(
              key: const Key('kioskDeletePage'),
              onPressed: () {
                ref.read(kioskPageProvider.notifier).set(page - 1);
                unawaited(
                  settings.update(
                    (s) => s.copyWith(
                      pages: [
                        for (final (i, p) in s.pages.indexed)
                          if (i != page - 1) p,
                      ],
                    ),
                  ),
                );
              },
              child: Text(l10n.kioskDeletePage),
            ),
          ],
          const SizedBox(width: 8),
          FilledButton(
            key: const Key('kioskLayoutDone'),
            onPressed: () => ref.read(kioskEditingProvider.notifier).set(false),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }
}
