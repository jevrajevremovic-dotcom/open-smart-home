import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../cameras/application/camera_providers.dart';
import '../../clap/clap_listener.dart' show clapCommandFor;
import '../../dashboard/application/home_summaries.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/domain/device_kind.dart';
import '../../devices/presentation/device_actions.dart';
import '../../devices/presentation/device_presentation.dart';
import '../application/kiosk_controller.dart';
import '../data/kiosk_layout.dart';
import 'glass.dart';
import 'kiosk_camera_panel.dart';
import 'kiosk_panels.dart';
import 'thermostat_dial.dart';
import '../../todo/todo_lists.dart';
import 'kiosk_board_panel.dart';
import 'kiosk_bubble.dart';
import 'kiosk_media_panel.dart';
import 'kiosk_todo_panel.dart';

/// `true` while the wall panel's layout is being edited on the tablet.
class KioskEditingController extends Notifier<bool> {
  @override
  bool build() {
    // Leaving kiosk mode ends editing (a listen, so entering kiosk mode
    // and starting to edit at once does not reset it).
    ref.listen(kioskActiveProvider, (_, active) {
      if (!active) state = false;
    });
    return false;
  }

  // ignore: use_setters_to_change_properties
  void set(bool editing) => state = editing;
}

final kioskEditingProvider = NotifierProvider<KioskEditingController, bool>(
  KioskEditingController.new,
);

String kioskPanelLabel(AppLocalizations l10n, KioskPanelType t) => switch (t) {
  KioskPanelType.camera => l10n.camerasTitle,
  KioskPanelType.weather => l10n.dashCardWeather,
  KioskPanelType.thermostat => l10n.kioskPanelThermostat,
  KioskPanelType.rooms => l10n.navRooms,
  KioskPanelType.shortcuts => l10n.kioskShortcuts,
  KioskPanelType.scenes => l10n.scenesTitle,
  KioskPanelType.calendar => l10n.calendarTitle,
  KioskPanelType.device => l10n.kioskPanelDevice,
  KioskPanelType.lists => l10n.todoTitle,
  KioskPanelType.board => l10n.boardTitle,
  KioskPanelType.media => l10n.mediaTitle,
};

/// Whether [p] has something to show right now (else it is left out,
/// except while editing).
bool _available(WidgetRef ref, KioskPanel p) {
  final settings = ref.watch(kioskSettingsProvider);
  return switch (p.type) {
    KioskPanelType.camera =>
      settings.showCameras &&
          ref.watch(cameraIdsProvider.select((ids) => ids.isNotEmpty)),
    KioskPanelType.calendar => settings.showCalendar,
    KioskPanelType.thermostat =>
      (p.entityId != null
          ? ref.watch(deviceProvider(p.entityId!)) != null
          : ref.watch(kioskThermostatIdProvider) != null),
    KioskPanelType.device =>
      p.entityId != null && ref.watch(deviceProvider(p.entityId!)) != null,
    KioskPanelType.scenes => ref.watch(
      dashboardSummaryProvider.select((s) => s.sceneIds.isNotEmpty),
    ),
    KioskPanelType.lists =>
      p.entityId != null
          ? ref.watch(deviceProvider(p.entityId!)) != null
          : ref.watch(todoListsProvider).isNotEmpty,
    _ => true,
  };
}

/// The panels of the current layout, laid out as a 12-column grid on
/// landscape tablets ([grid]) or one column otherwise.
class KioskLayoutView extends ConsumerWidget {
  const KioskLayoutView({
    super.key,
    required this.grid,
    this.header = const [],
  });

  final bool grid;

  /// Shown above the panels in the scrolling column.
  final List<Widget> header;

  static const gap = 20.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = ref.watch(kioskEditingProvider);
    final layout = ref.watch(
      kioskSettingsProvider.select((s) => s.effectiveLayout),
    );
    final panels = [
      for (final p in layout.panels)
        if (editing || _available(ref, p)) p,
    ];
    // Without a scenes panel the scenes become chips in the shortcuts.
    final scenesShown = panels.any((p) => p.type == KioskPanelType.scenes);

    Widget panel(KioskPanel p, {required bool fill}) {
      final child = _PanelBody(
        panel: p,
        fill: fill,
        scenesShown: scenesShown,
        available: !editing || _available(ref, p),
      );
      return editing
          ? _EditablePanel(panel: p, layout: layout, grid: grid, child: child)
          : child;
    }

    if (!grid) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 24),
        children: [
          ...header,
          for (final p in panels) ...[
            const SizedBox(height: 16),
            _columnSized(p, panel(p, fill: false)),
          ],
          if (editing) const SizedBox(height: 120),
        ],
      );
    }

    final rows = KioskLayout.rows(panels);
    if (rows.isEmpty) {
      return Center(child: Text(context.l10n.kioskLayoutEmpty));
    }
    return LayoutBuilder(
      builder: (context, c) {
        final units = rows.fold<int>(
          0,
          (a, r) => a + r.map((p) => p.height).reduce(max),
        );
        final perUnit = (c.maxHeight - gap * (rows.length - 1)) / units;
        // Too many rows for one screen: scroll instead of squeezing.
        final scroll = perUnit < 130;
        Widget row(List<KioskPanel> r) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, p) in r.indexed) ...[
              if (i > 0) const SizedBox(width: gap),
              Expanded(flex: p.span, child: panel(p, fill: true)),
            ],
          ],
        );
        final children = <Widget>[
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: gap),
            if (scroll)
              SizedBox(
                height: 240.0 * r.map((p) => p.height).reduce(max),
                child: row(r),
              )
            else
              Expanded(flex: r.map((p) => p.height).reduce(max), child: row(r)),
          ],
        ];
        return scroll
            ? SingleChildScrollView(child: Column(children: children))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              );
      },
    );
  }

  /// Heights of panels that do not size themselves in a column.
  static Widget _columnSized(KioskPanel p, Widget child) => switch (p.type) {
    KioskPanelType.camera => SizedBox(height: 300.0 * p.height, child: child),
    KioskPanelType.thermostat => SizedBox(height: 420, child: child),
    KioskPanelType.calendar => SizedBox(height: 520, child: child),
    KioskPanelType.device => SizedBox(height: 150.0 * p.height, child: child),
    KioskPanelType.lists => SizedBox(height: 360.0 * p.height, child: child),
    KioskPanelType.board => SizedBox(height: 360.0 * p.height, child: child),
    KioskPanelType.media => SizedBox(height: 300.0 * p.height, child: child),
    _ => child,
  };
}

class _PanelBody extends ConsumerWidget {
  const _PanelBody({
    required this.panel,
    required this.fill,
    required this.scenesShown,
    required this.available,
  });

  final KioskPanel panel;

  /// In the grid (fills its cell) rather than the scrolling column.
  final bool fill;
  final bool scenesShown;
  final bool available;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (!available) {
      // Only seen while editing: say why it is empty.
      return GlassPanel(
        child: Center(
          child: Text(
            l10n.kioskPanelUnavailable(kioskPanelLabel(l10n, panel.type)),
            textAlign: TextAlign.center,
            style: const TextStyle(color: GlassColors.muted),
          ),
        ),
      );
    }
    final scenes = ref.watch(
      dashboardSummaryProvider.select((s) => s.sceneIds),
    );
    return switch (panel.type) {
      KioskPanelType.camera => const KioskCameraPanel(),
      KioskPanelType.weather => const KioskWeatherPanel(),
      KioskPanelType.thermostat => KioskThermostatPanel(
        deviceId: panel.entityId ?? ref.watch(kioskThermostatIdProvider)!,
      ),
      KioskPanelType.rooms =>
        ref.watch(kioskSettingsProvider.select((s) => s.bubble))
            ? KioskBubbleRoomsPanel(scrollable: fill)
            : KioskRoomsPanel(scrollable: fill),
      KioskPanelType.shortcuts => KioskShortcutsPanel(
        scrollable: fill,
        sceneIds: scenesShown ? const [] : scenes,
      ),
      KioskPanelType.scenes => KioskScenesPanel(
        sceneIds: scenes,
        scrollable: fill,
      ),
      KioskPanelType.calendar => const KioskCalendarPanel(),
      KioskPanelType.device => KioskDevicePanel(deviceId: panel.entityId!),
      KioskPanelType.board => const KioskBoardPanel(),
      KioskPanelType.media => KioskMediaPanel(playerId: panel.entityId),
      KioskPanelType.lists => KioskTodoPanel(
        listId: panel.entityId ?? ref.watch(todoListsProvider).first.id,
      ),
    };
  }
}

/// One device as a big button: tap does its main action, long press opens
/// it.
class KioskDevicePanel extends ConsumerWidget {
  const KioskDevicePanel({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final d = ref.watch(deviceProvider(deviceId));
    if (d == null) return const SizedBox.shrink();
    final on = d.state.isOn == true || d.state.isActive == true;
    final theme = Theme.of(context);
    return GestureDetector(
      key: ValueKey('kioskDevice-$deviceId'),
      onTap: () {
        final command = clapCommandFor(d);
        if (command == null) {
          context.push(AppRoutes.device(d.id, kiosk: true));
        } else {
          runDeviceCommand(context, ref, d, command);
        }
      },
      onLongPress: () => context.push(AppRoutes.device(d.id, kiosk: true)),
      child: GlassPanel(
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on
                    ? const Color(0xFFFFC857)
                    : Colors.white.withValues(alpha: 0.12),
              ),
              child: Icon(
                DevicePresentation.icon(d),
                size: 34,
                color: on ? const Color(0xFF3A2A00) : GlassColors.text,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: GlassColors.text,
                    ),
                  ),
                  Text(
                    DevicePresentation.status(l10n, d),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: GlassColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A panel while editing: long press and drag to move it onto another
/// panel; buttons change size, order and content.
class _EditablePanel extends ConsumerWidget {
  const _EditablePanel({
    required this.panel,
    required this.layout,
    required this.grid,
    required this.child,
  });

  final KioskPanel panel;
  final KioskLayout layout;
  final bool grid;
  final Widget child;

  void _save(WidgetRef ref, KioskLayout next) => ref
      .read(kioskSettingsProvider.notifier)
      .update((s) => s.copyWith(layout: next));

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
              await settings.update(
                (s) => s.copyWith(
                  layout: s.effectiveLayout.add(type, entityId: entity),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.kioskAddPanel),
          ),
          TextButton(
            key: const Key('kioskLayoutReset'),
            onPressed: () =>
                settings.update((s) => s.copyWith(resetLayout: true)),
            child: Text(l10n.dashLayoutReset),
          ),
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
