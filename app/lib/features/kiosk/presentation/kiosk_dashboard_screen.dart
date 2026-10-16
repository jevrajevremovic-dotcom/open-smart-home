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
import '../../devices/application/device_providers.dart';
import '../../devices/presentation/stale_data_banner.dart';
import '../application/kiosk_controller.dart';
import '../../notifications/application/notifications_provider.dart';
import '../../notifications/presentation/notifications.dart';
import 'glass.dart';
import 'kiosk_layout_view.dart';
import 'kiosk_panels.dart';
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
          key: const Key('kioskEditLayout'),
          tooltip: l10n.kioskEditLayout,
          color: GlassColors.muted,
          icon: const Icon(Icons.dashboard_customize_outlined),
          onPressed: () async {
            if (await unlockKioskEditing(context, ref)) {
              ref.read(kioskEditingProvider.notifier).set(true);
            }
          },
        ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = ref.watch(kioskEditingProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (editing) const KioskEditBar() else const _Header(),
          const _Problems(),
          const SizedBox(height: KioskLayoutView.gap),
          const Expanded(child: KioskLayoutView(grid: true)),
          if (!editing) ...[
            const SizedBox(height: KioskLayoutView.gap),
            const KioskStatusBar(),
          ],
        ],
      ),
    );
  }
}

class _ColumnLayout extends ConsumerWidget {
  const _ColumnLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = ref.watch(kioskEditingProvider);
    final refresh = ref.read(webSocketManagerProvider)?.retryNow;
    return RefreshIndicator(
      onRefresh: () async => refresh?.call(),
      child: KioskLayoutView(
        grid: false,
        header: [
          if (editing) const KioskEditBar() else const _Header(),
          const _Problems(),
          if (!editing) ...[const SizedBox(height: 16), const KioskStatusBar()],
        ],
      ),
    );
  }
}
