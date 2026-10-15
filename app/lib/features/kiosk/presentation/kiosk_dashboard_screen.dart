import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../authentication/application/session_controller.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../../app/theme/app_theme.dart';
import '../../clap/clap_listener.dart';
import '../../dashboard/application/home_summaries.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/presentation/stale_data_banner.dart';
import '../application/kiosk_controller.dart';
import '../../cameras/application/camera_providers.dart';
import '../../notifications/application/notifications_provider.dart';
import '../../notifications/presentation/notifications.dart';
import 'glass.dart';
import 'kiosk_camera_panel.dart';
import 'kiosk_panels.dart';
import 'thermostat_dial.dart';
import 'pin_dialog.dart';

/// Text is enlarged on the wall panel so it is readable from a distance.
const double kioskTextScale = 1.2;

/// Wraps kiosk pages with larger text.
class KioskScale extends StatelessWidget {
  const KioskScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = MediaQuery.textScalerOf(context).scale(1);
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(base * kioskTextScale)),
      child: child,
    );
  }
}

/// Fullscreen wall-panel dashboard on a glass-and-gradient backdrop:
/// clock, weather, thermostat, rooms, shortcuts, scenes and a status bar.
///
/// Landscape tablets get a fixed grid that fits one screen; portrait and
/// small screens get the same panels in one scrolling column.
class KioskDashboardScreen extends ConsumerWidget {
  const KioskDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: KioskClapListener(
          child: KioskBackdrop(
            child: MockModeBanner(
              child: SafeArea(
                child: KioskScale(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final grid =
                          c.maxWidth >= 1000 && c.maxWidth > c.maxHeight * 1.15;
                      return grid ? const _GridLayout() : const _ColumnLayout();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final title =
        ref.watch(homeSnapshotProvider.select((s) => s.locationName)) ??
        ref.watch(serverConfigProvider).value?.locationName ??
        l10n.appTitle;
    final hasChips = ref.watch(
      kioskSettingsProvider.select((s) => s.statusEntityIds.isNotEmpty),
    );
    final notifications = ref.watch(
      haNotificationsProvider.select((n) => n.value?.length ?? 0),
    );
    final connected = ref.watch(
      connectionStatusProvider.select((s) => s.value?.isConnected ?? false),
    );
    return Row(
      children: [
        // Left: chosen status chips; the clock moves right to make room.
        Expanded(
          child: hasChips
              ? const KioskStatusChips()
              : Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: KioskHeaderClock(subtitle: title),
                  ),
                ),
        ),
        if (hasChips) ...[
          const SizedBox(width: 16),
          KioskHeaderClock(alignEnd: true, subtitle: title),
        ],
        if (!connected) ...[
          const SizedBox(width: 12),
          const ConnectionIndicator(),
        ],
        if (notifications > 0) ...[
          const SizedBox(width: 8),
          IconButton(
            key: const Key('kioskNotifications'),
            tooltip: l10n.notificationsCount(notifications),
            color: GlassColors.text,
            onPressed: () => showNotificationsSheet(context),
            icon: Badge.count(
              count: notifications,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
        const SizedBox(width: 12),
        const KioskPeople(),
        const SizedBox(width: 4),
        IconButton(
          key: const Key('kioskExit'),
          tooltip: l10n.kioskExit,
          color: GlassColors.muted,
          icon: const Icon(Icons.lock_outline),
          onPressed: () async {
            if (await showKioskExitDialog(context, ref) && context.mounted) {
              context.go(AppRoutes.home);
            }
          },
        ),
      ],
    );
  }
}

/// Status shown above the panels only when something is wrong.
class _Problems extends StatelessWidget {
  const _Problems();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StaleDataBanner(),
      ConnectionProblemCard(),
      CriticalAlertsBanner(),
    ],
  );
}

class _GridLayout extends ConsumerWidget {
  const _GridLayout();

  static const _gap = 20.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thermostat = ref.watch(kioskThermostatIdProvider);
    final scenes = ref.watch(
      dashboardSummaryProvider.select((s) => s.sceneIds),
    );

    final cameras =
        ref.watch(kioskSettingsProvider.select((s) => s.showCameras)) &&
        ref.watch(cameraIdsProvider.select((ids) => ids.isNotEmpty));

    // Shown even without HA calendars: the month view is still useful and
    // the panel explains how to add one.
    final calendar = ref.watch(
      kioskSettingsProvider.select((s) => s.showCalendar),
    );

    // With cameras the picture takes the top-left, rooms move down.
    final top = <Widget>[
      if (cameras) const Expanded(flex: 6, child: KioskCameraPanel()),
      const Expanded(flex: 4, child: KioskWeatherPanel()),
      if (thermostat != null)
        Expanded(flex: 4, child: KioskThermostatPanel(deviceId: thermostat)),
      if (!cameras) const Expanded(flex: 4, child: KioskRoomsPanel()),
    ];
    // With the calendar, scenes become chips in the shortcuts panel.
    final bottom = <Widget>[
      if (cameras)
        Expanded(flex: calendar ? 3 : 4, child: const KioskRoomsPanel()),
      Expanded(
        flex: calendar ? 4 : (cameras ? 6 : 8),
        child: KioskShortcutsPanel(sceneIds: calendar ? scenes : const []),
      ),
      if (scenes.isNotEmpty && !calendar)
        Expanded(flex: 4, child: KioskScenesPanel(sceneIds: scenes)),
      if (calendar) const Expanded(flex: 7, child: KioskCalendarPanel()),
    ];
    List<Widget> spaced(List<Widget> items) => [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: _gap),
        items[i],
      ],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          const _Problems(),
          const SizedBox(height: _gap),
          Expanded(
            flex: calendar ? 11 : 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: spaced(top),
            ),
          ),
          const SizedBox(height: _gap),
          Expanded(
            flex: calendar ? 10 : 8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: spaced(bottom),
            ),
          ),
          const SizedBox(height: _gap),
          const KioskStatusBar(),
        ],
      ),
    );
  }
}

class _ColumnLayout extends ConsumerWidget {
  const _ColumnLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thermostat = ref.watch(kioskThermostatIdProvider);
    final scenes = ref.watch(
      dashboardSummaryProvider.select((s) => s.sceneIds),
    );
    final cameras =
        ref.watch(kioskSettingsProvider.select((s) => s.showCameras)) &&
        ref.watch(cameraIdsProvider.select((ids) => ids.isNotEmpty));
    // Shown even without HA calendars: the month view is still useful and
    // the panel explains how to add one.
    final calendar = ref.watch(
      kioskSettingsProvider.select((s) => s.showCalendar),
    );
    final refresh = ref.read(webSocketManagerProvider)?.retryNow;
    const gap = SizedBox(height: 16);
    return RefreshIndicator(
      onRefresh: () async => refresh?.call(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 24),
        children: [
          const _Header(),
          const _Problems(),
          gap,
          const KioskStatusBar(),
          if (cameras) ...[
            gap,
            const SizedBox(height: 300, child: KioskCameraPanel()),
          ],
          gap,
          const KioskWeatherPanel(),
          if (thermostat != null) ...[
            gap,
            SizedBox(
              height: 420,
              child: KioskThermostatPanel(deviceId: thermostat),
            ),
          ],
          gap,
          const KioskShortcutsPanel(scrollable: false),
          if (calendar) ...[
            gap,
            const SizedBox(height: 520, child: KioskCalendarPanel()),
          ],
          if (scenes.isNotEmpty) ...[
            gap,
            KioskScenesPanel(sceneIds: scenes, scrollable: false),
          ],
          gap,
          const KioskRoomsPanel(scrollable: false),
        ],
      ),
    );
  }
}
