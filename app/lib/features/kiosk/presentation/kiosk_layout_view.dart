import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/widgets/time_picker.dart';
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
import 'kiosk_energy_panel.dart';
import 'kiosk_media_panel.dart';
import 'kiosk_todo_panel.dart';

part 'kiosk_layout_editor.dart';
part 'kiosk_pages_editor.dart';

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

/// Kiosk page on screen: 0 = home, then [KioskSettings.pages].
class KioskPageController extends Notifier<int> {
  @override
  int build() => 0;

  // ignore: use_setters_to_change_properties
  void set(int page) => state = page;
}

final kioskPageProvider = NotifierProvider<KioskPageController, int>(
  KioskPageController.new,
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
  KioskPanelType.energy => l10n.energyTitle,
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
    this.page = 0,
    this.header = const [],
  });

  final bool grid;

  /// 0 = home, then the extra pages.
  final int page;

  /// Shown above the panels in the scrolling column.
  final List<Widget> header;

  static const gap = 20.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = ref.watch(kioskEditingProvider);
    final layout = ref.watch(
      kioskSettingsProvider.select((s) => s.layoutOf(page)),
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
          ? _EditablePanel(
              panel: p,
              layout: layout,
              page: page,
              grid: grid,
              child: child,
            )
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
    KioskPanelType.energy => SizedBox(height: 280.0 * p.height, child: child),
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
      KioskPanelType.energy => const KioskEnergyPanel(),
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
