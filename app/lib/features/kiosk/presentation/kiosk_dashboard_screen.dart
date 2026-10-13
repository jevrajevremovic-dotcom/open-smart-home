import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../authentication/application/session_controller.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../../app/theme/app_theme.dart';
import '../../dashboard/application/home_summaries.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/presentation/stale_data_banner.dart';
import '../../weather/application/weather_providers.dart';
import '../application/kiosk_controller.dart';
import '../../cameras/application/camera_providers.dart';
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
        body: KioskBackdrop(
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
    final hasWeather = ref.watch(homeWeatherProvider.select((w) => w != null));
    final thermostat = ref.watch(kioskThermostatIdProvider);
    final scenes = ref.watch(
      dashboardSummaryProvider.select((s) => s.sceneIds),
    );

    final cameras =
        ref.watch(kioskSettingsProvider.select((s) => s.showCameras)) &&
        ref.watch(cameraIdsProvider.select((ids) => ids.isNotEmpty));

    // With cameras the picture takes the top-left, rooms move down.
    final top = <Widget>[
      if (cameras) const Expanded(flex: 6, child: KioskCameraPanel()),
      if (hasWeather) const Expanded(flex: 4, child: KioskWeatherPanel()),
      if (thermostat != null)
        Expanded(flex: 4, child: KioskThermostatPanel(deviceId: thermostat)),
      if (!cameras) const Expanded(flex: 4, child: KioskRoomsPanel()),
    ];
    final bottom = <Widget>[
      if (cameras) const Expanded(flex: 4, child: KioskRoomsPanel()),
      Expanded(flex: cameras ? 6 : 8, child: const KioskShortcutsPanel()),
      if (scenes.isNotEmpty)
        Expanded(flex: 4, child: KioskScenesPanel(sceneIds: scenes)),
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
            flex: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: spaced(top),
            ),
          ),
          const SizedBox(height: _gap),
          Expanded(
            flex: 8,
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
    final hasWeather = ref.watch(homeWeatherProvider.select((w) => w != null));
    final cameras =
        ref.watch(kioskSettingsProvider.select((s) => s.showCameras)) &&
        ref.watch(cameraIdsProvider.select((ids) => ids.isNotEmpty));
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
          if (hasWeather) ...[gap, const KioskWeatherPanel()],
          if (thermostat != null) ...[
            gap,
            SizedBox(
              height: 420,
              child: KioskThermostatPanel(deviceId: thermostat),
            ),
          ],
          gap,
          const KioskShortcutsPanel(scrollable: false),
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
