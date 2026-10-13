import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../integrations/home_assistant/websocket/connection_status.dart';
import '../../authentication/application/session_controller.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/data/home_state_repository.dart';
import '../../devices/domain/device_command.dart';
import '../../devices/presentation/device_actions.dart';
import '../../devices/presentation/device_grid.dart';
import '../../devices/presentation/device_presentation.dart';
import '../../devices/presentation/stale_data_banner.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../rooms/presentation/room_card.dart';
import '../../kiosk/application/kiosk_controller.dart';
import '../application/home_summaries.dart';

/// Default home screen, generated from the available devices: summary,
/// favorites, scenes, rooms and things that need attention.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title =
        ref.watch(homeSnapshotProvider.select((s) => s.locationName)) ??
        ref.watch(serverConfigProvider).value?.locationName ??
        context.l10n.appTitle;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ConnectionIndicator(),
          ),
        ],
      ),
      body: const MockModeBanner(child: DashboardBody()),
    );
  }
}

/// Dashboard content, shared by the normal and the kiosk dashboard.
///
/// Narrow or portrait screens get one scrolling column. Large screens and
/// landscape tablets get two panes: status on the left, favorites and rooms
/// on the right, so a wall panel shows everything without scrolling much.
class DashboardBody extends ConsumerWidget {
  const DashboardBody({super.key, this.kiosk = false});

  /// Kiosk mode hides links that leave the kiosk routes.
  final bool kiosk;

  static const _pad = EdgeInsets.symmetric(horizontal: 16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final twoPanes =
            width >= Breakpoints.large ||
            (width >= Breakpoints.expanded && width > constraints.maxHeight);
        final refresh = ref.read(webSocketManagerProvider)?.retryNow;
        if (!twoPanes) {
          return RefreshIndicator(
            onRefresh: () async => refresh?.call(),
            child: CustomScrollView(
              slivers: [
                ..._statusSlivers(ref),
                ..._contentSlivers(context, ref),
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: width >= Breakpoints.large ? 400 : 340,
              child: CustomScrollView(slivers: _statusSlivers(ref)),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => refresh?.call(),
                child: CustomScrollView(slivers: _contentSlivers(context, ref)),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Connection, summary, alerts, scenes, attention.
  List<Widget> _statusSlivers(WidgetRef ref) {
    final sceneIds = ref.watch(
      dashboardSummaryProvider.select((s) => s.sceneIds),
    );
    final syncing = ref.watch(syncStatusProvider) == SyncStatus.syncing;
    Widget box(Widget child) => SliverPadding(
      padding: _pad,
      sliver: SliverToBoxAdapter(child: child),
    );
    return [
      const SliverPadding(
        padding: _pad,
        sliver: SliverToBoxAdapter(child: StaleDataBanner()),
      ),
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverToBoxAdapter(child: ConnectionProblemCard()),
      ),
      if (syncing) const SliverToBoxAdapter(child: LinearProgressIndicator()),
      box(const DashboardSummaryRow()),
      box(const CriticalAlertsBanner()),
      if (!kiosk)
        box(
          Consumer(
            builder: (context, _, _) => Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('openEnergy'),
                onPressed: () => context.push(AppRoutes.energy),
                icon: const Icon(Icons.bolt),
                label: Text(context.l10n.energyTitle),
              ),
            ),
          ),
        ),
      if (sceneIds.isNotEmpty) ...[
        box(
          Consumer(
            builder: (context, _, _) => SectionHeader(context.l10n.scenesTitle),
          ),
        ),
        box(SceneButtons(sceneIds: sceneIds)),
      ],
      box(const AttentionSection()),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }

  /// Favorites and rooms.
  List<Widget> _contentSlivers(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final favorites = ref.watch(existingFavoritesProvider);
    final rooms = ref.watch(roomsProvider);
    final hasUnassigned = ref.watch(
      deviceIdsByRoomProvider.select((m) => m.containsKey(null)),
    );
    Widget box(Widget child) => SliverPadding(
      padding: _pad,
      sliver: SliverToBoxAdapter(child: child),
    );
    return [
      box(SectionHeader(l10n.navFavorites)),
      SliverPadding(
        padding: _pad,
        sliver: favorites.isEmpty
            ? SliverToBoxAdapter(
                child: EmptyHint(
                  icon: Icons.star_border,
                  text: l10n.favoritesEmpty,
                ),
              )
            : DeviceSliverGrid(deviceIds: favorites),
      ),
      if (rooms.isNotEmpty || hasUnassigned) ...[
        box(
          SectionHeader(
            l10n.navRooms,
            trailing: kiosk
                ? null
                : TextButton(
                    onPressed: () => context.go(AppRoutes.rooms),
                    child: Text(l10n.allDevices),
                  ),
          ),
        ),
        SliverPadding(
          padding: _pad,
          sliver: RoomSliverGrid(
            rooms: [
              for (final r in rooms) (r.id, r.name, r.icon),
              if (hasUnassigned) (null, l10n.roomNoRoom, null),
            ],
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
    ];
  }
}

class ConnectionIndicator extends ConsumerWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ConnectionStatusChip(
    status:
        ref.watch(connectionStatusProvider).value ?? HaConnectionStatus.initial,
  );
}

/// Shown only when something is wrong with the connection.
class ConnectionProblemCard extends ConsumerWidget {
  const ConnectionProblemCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status =
        ref.watch(connectionStatusProvider).value ?? HaConnectionStatus.initial;
    final connecting =
        status.state == HaConnectionState.connecting ||
        status.state == HaConnectionState.authenticating;
    if (status.isConnected || connecting) return const SizedBox.shrink();

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (status.failure != null)
              InlineNotice.warning(failureMessage(l10n, status.failure!)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: status.isTerminal
                  ? FilledButton.icon(
                      onPressed: () => ref
                          .read(sessionControllerProvider.notifier)
                          .signOut(),
                      icon: const Icon(Icons.login),
                      label: Text(l10n.signInAgain),
                    )
                  : OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(webSocketManagerProvider)?.retryNow(),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retryNow),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardSummaryRow extends ConsumerWidget {
  const DashboardSummaryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(dashboardSummaryProvider);
    final power = s.powerDeviceId == null
        ? null
        : ref.watch(deviceProvider(s.powerDeviceId!));
    final locale = l10n.localeName;
    final colors = context.statusColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two equal columns on phones; natural widths on larger screens.
        final cardWidth =
            WindowSize.fromWidth(constraints.maxWidth) == WindowSize.compact
            ? (constraints.maxWidth - 12) / 2
            : null;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryCard(
                width: cardWidth,
                icon: Icons.thermostat,
                label: l10n.summaryTemperature,
                value: s.averageTemperature == null
                    ? null
                    : formatNumber(locale, s.averageTemperature!, unit: '°'),
              ),
              _SummaryCard(
                width: cardWidth,
                icon: Icons.water_drop_outlined,
                label: l10n.summaryHumidity,
                value: s.averageHumidity == null
                    ? null
                    : formatNumber(locale, s.averageHumidity!, unit: '%'),
              ),
              if (s.lightsTotal > 0)
                _SummaryCard(
                  width: cardWidth,
                  icon: Icons.lightbulb_outline,
                  label: l10n.summaryLights,
                  value: l10n.lightsOnOf(s.lightsOn, s.lightsTotal),
                ),
              _SummaryCard(
                width: cardWidth,
                icon: Icons.door_front_door_outlined,
                label: l10n.summaryOpenings,
                value: '${s.openingIds.length}',
                color: s.openingIds.isEmpty ? null : colors.warning,
              ),
              if (power != null)
                _SummaryCard(
                  width: cardWidth,
                  icon: Icons.bolt,
                  label: l10n.summaryPower,
                  value: DevicePresentation.sensorValue(l10n, power.state),
                  tooltip: power.name,
                ),
              _SummaryCard(
                width: cardWidth,
                icon: Icons.warning_amber_rounded,
                label: l10n.summaryAlerts,
                value: '${s.criticalIds.length}',
                color: s.criticalIds.isEmpty ? null : colors.critical,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.tooltip,
  });

  final double? width;
  final IconData icon;
  final String label;

  /// `null` = no such data in this home.
  final String? value;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final card = Card.filled(
      margin: EdgeInsets.zero,
      child: ConstrainedBox(
        // Bounded width so long labels wrap instead of overflowing.
        constraints: width != null
            ? BoxConstraints.tightFor(width: width)
            : const BoxConstraints(minWidth: 140, maxWidth: 220),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color ?? theme.colorScheme.primary),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.labelMedium),
                    Text(
                      value ?? '—',
                      semanticsLabel: value ?? l10n.valueNotAvailable,
                      style: theme.textTheme.titleLarge?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? card : Tooltip(message: tooltip, child: card);
  }
}

class CriticalAlertsBanner extends ConsumerWidget {
  const CriticalAlertsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(
      dashboardSummaryProvider.select((s) => s.criticalIds),
    );
    if (ids.isEmpty) return const SizedBox.shrink();
    final colors = context.statusColors;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card.filled(
        color: colors.critical,
        child: Column(
          children: [
            for (final id in ids)
              Consumer(
                builder: (context, ref, _) {
                  final d = ref.watch(deviceProvider(id));
                  if (d == null) return const SizedBox.shrink();
                  return ListTile(
                    leading: Icon(
                      DevicePresentation.icon(d),
                      color: colors.onCritical,
                    ),
                    title: Text(
                      d.name,
                      style: TextStyle(
                        color: colors.onCritical,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      DevicePresentation.status(context.l10n, d),
                      style: TextStyle(color: colors.onCritical),
                    ),
                    onTap: () => context.push(
                      AppRoutes.device(
                        id,
                        kiosk: ref.read(kioskActiveProvider),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class SceneButtons extends ConsumerWidget {
  const SceneButtons({super.key, required this.sceneIds});

  final List<String> sceneIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final id in sceneIds)
          Consumer(
            builder: (context, ref, _) {
              final d = ref.watch(deviceProvider(id));
              if (d == null) return const SizedBox.shrink();
              return ActionChip(
                avatar: const Icon(Icons.play_arrow),
                label: Text(d.name),
                onPressed: d.available
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        if (await runDeviceCommand(
                          context,
                          ref,
                          d,
                          const Activate(),
                        )) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(l10n.sceneActivated(d.name)),
                            ),
                          );
                        }
                      }
                    : null,
              );
            },
          ),
      ],
    );
  }
}

class AttentionSection extends ConsumerWidget {
  const AttentionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(dashboardSummaryProvider);
    if (s.lowBatteryIds.isEmpty && s.unavailableIds.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = context.statusColors;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card.outlined(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(Icons.build_circle_outlined, color: colors.warning),
          title: Text(l10n.dashboardAttention),
          subtitle: Text(
            [
              if (s.lowBatteryIds.isNotEmpty)
                l10n.lowBatteryCount(s.lowBatteryIds.length),
              if (s.unavailableIds.isNotEmpty)
                l10n.unavailableCount(s.unavailableIds.length),
            ].join(' · '),
          ),
          children: [
            for (final id in [...s.lowBatteryIds, ...s.unavailableIds])
              Consumer(
                builder: (context, ref, _) {
                  final d = ref.watch(deviceProvider(id));
                  if (d == null) return const SizedBox.shrink();
                  return ListTile(
                    leading: Icon(
                      d.available ? Icons.battery_alert : Icons.cloud_off,
                      color: colors.warning,
                    ),
                    title: Text(d.name),
                    subtitle: Text(
                      d.available && d.metadata.batteryPercent != null
                          ? l10n.batteryLevel(d.metadata.batteryPercent!)
                          : DevicePresentation.status(l10n, d),
                    ),
                    onTap: () => context.push(
                      AppRoutes.device(
                        id,
                        kiosk: ref.read(kioskActiveProvider),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
