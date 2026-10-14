import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
import '../../devices/presentation/all_lights.dart';
import '../../devices/presentation/device_actions.dart';
import '../../devices/presentation/device_grid.dart';
import '../../devices/presentation/device_presentation.dart';
import '../../devices/presentation/stale_data_banner.dart';
import '../../assist/presentation/assist_sheet.dart';
import '../../devices/domain/capability.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../media/application/media_providers.dart';
import '../../media/presentation/media_artwork.dart';
import '../../media/presentation/media_sheet.dart';
import '../../notifications/presentation/notifications.dart';
import '../../restricted/application/restricted_mode.dart';
import '../../rooms/presentation/room_card.dart';
import '../../kiosk/application/kiosk_controller.dart';
import '../../weather/application/weather_providers.dart';
import '../../weather/presentation/weather_card.dart';
import '../application/home_summaries.dart';

/// Default home screen, generated from the available devices: summary,
/// favorites, scenes, rooms and things that need attention.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: const _HomeSwitcher(),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ConnectionIndicator(),
          ),
        ],
      ),
      // Assist can unlock doors by voice: not in child / guest mode.
      floatingActionButton: ref.watch(restrictedModeProvider).enabled
          ? null
          : FloatingActionButton(
              key: const Key('openAssist'),
              tooltip: context.l10n.assistTitle,
              onPressed: () => showAssist(context),
              child: const Icon(Icons.assistant_outlined),
            ),
      body: const MockModeBanner(child: DashboardBody()),
    );
  }
}

/// The greeting; with several homes, tapping it switches between them.
class _HomeSwitcher extends ConsumerWidget {
  const _HomeSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title =
        ref.watch(homeSnapshotProvider.select((s) => s.locationName)) ??
        ref.watch(serverConfigProvider).value?.locationName ??
        context.l10n.appTitle;
    final homes = ref.watch(savedHomesProvider).value ?? const [];
    final greeting = DashboardGreeting(
      homeName: title,
      showSwitcher: homes.length > 1,
    );
    if (homes.length < 2) return greeting;
    final active = ref.watch(activeProfileProvider);
    return PopupMenuButton<String>(
      key: const Key('homeSwitcher'),
      tooltip: context.l10n.homesTitle,
      onSelected: (id) {
        final home = homes.firstWhere((h) => h.profile.id == id);
        ref.read(sessionControllerProvider.notifier).switchTo(home.profile);
      },
      itemBuilder: (_) => [
        for (final h in homes)
          CheckedPopupMenuItem(
            key: ValueKey('switchHome-${h.profile.id}'),
            value: h.profile.id,
            checked: h.profile.id == active?.id,
            child: Text(h.name),
          ),
      ],
      child: greeting,
    );
  }
}

/// Time-of-day greeting and date above the home's name.
class DashboardGreeting extends StatelessWidget {
  const DashboardGreeting({
    super.key,
    required this.homeName,
    this.showSwitcher = false,
  });

  final String homeName;

  /// A small arrow hints that the name opens the home switcher.
  final bool showSwitcher;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final greeting = switch (now.hour) {
      >= 5 && < 12 => l10n.greetingMorning,
      >= 12 && < 18 => l10n.greetingAfternoon,
      >= 18 && < 23 => l10n.greetingEvening,
      _ => l10n.greetingNight,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$greeting · ${DateFormat.MMMEd(l10n.localeName).format(now)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                homeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            if (showSwitcher) const Icon(Icons.arrow_drop_down),
          ],
        ),
      ],
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
              key: const Key('dashboardStatusPane'),
              width: width >= Breakpoints.large ? 400 : 340,
              child: CustomScrollView(slivers: _statusSlivers(ref)),
            ),
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
      box(WeatherSection(allowDeviceLocation: !kiosk)),
      box(const NowPlayingCard()),
      box(const CriticalAlertsBanner()),
      box(const NotificationsBanner()),
      if (!kiosk)
        box(
          Consumer(
            builder: (context, _, _) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      key: const Key('openEnergy'),
                      onPressed: () => context.push(AppRoutes.energy),
                      icon: const Icon(Icons.bolt),
                      label: Text(context.l10n.energyTitle),
                    ),
                    FilledButton.tonalIcon(
                      key: const Key('openCalendar'),
                      onPressed: () => context.push(AppRoutes.calendar),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(context.l10n.calendarTitle),
                    ),
                    FilledButton.tonalIcon(
                      key: const Key('openActivity'),
                      onPressed: () => context.push(AppRoutes.activity),
                      icon: const Icon(Icons.history),
                      label: Text(context.l10n.activityTitle),
                    ),
                  ],
                ),
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
    final outdoor = ref.watch(
      homeWeatherProvider.select((w) => w?.now.temperature),
    );

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
              if (outdoor != null)
                _SummaryCard(
                  width: cardWidth,
                  icon: Icons.wb_cloudy_outlined,
                  label: l10n.summaryOutdoor,
                  value: formatNumber(locale, outdoor, unit: '°'),
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
                  key: const Key('summaryLights'),
                  width: cardWidth,
                  icon: Icons.lightbulb_outline,
                  label: l10n.summaryLights,
                  value: l10n.lightsOnOf(s.lightsOn, s.lightsTotal),
                  onTap: () => showAllLightsSheet(context),
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
    super.key,
    this.onTap,
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = color ?? theme.colorScheme.primary;
    final card = Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          // Bounded width so long labels wrap instead of overflowing.
          constraints: width != null
              ? BoxConstraints.tightFor(width: width)
              : const BoxConstraints(minWidth: 150, maxWidth: 220),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        value ?? '—',
                        semanticsLabel: value ?? l10n.valueNotAvailable,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

/// The media player that is playing, with play/pause.
class NowPlayingCard extends ConsumerWidget {
  const NowPlayingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = ref.watch(nowPlayingIdProvider);
    final hasPlayers = ref.watch(
      mediaPlayerIdsProvider.select((ids) => ids.isNotEmpty),
    );
    final d = id == null ? null : ref.watch(deviceProvider(id));
    // Always present, so it's clear where music lives; without players
    // the sheet explains what to add in Home Assistant.
    final scheme = Theme.of(context).colorScheme;
    final playing = d?.state.raw == 'playing';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        key: const Key('nowPlayingCard'),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          leading: d != null
              ? MediaArtwork(deviceId: d.id, size: 48)
              : CircleAvatar(
                  radius: 24,
                  backgroundColor: scheme.secondaryContainer,
                  child: Icon(
                    Icons.music_note,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
          title: Text(
            d == null ? l10n.mediaTitle : d.state.mediaTitle ?? d.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            d == null
                ? (hasPlayers ? l10n.mediaIdle : l10n.mediaNoPlayersShort)
                : [?d.state.mediaArtist, d.name].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => showMediaSheet(context, playerId: d?.id),
          trailing: d != null && d.supports(Capability.mediaPause)
              ? IconButton.filledTonal(
                  tooltip: l10n.mediaPlayPause,
                  onPressed: () =>
                      runDeviceCommand(context, ref, d, const MediaPlayPause()),
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                )
              : const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
