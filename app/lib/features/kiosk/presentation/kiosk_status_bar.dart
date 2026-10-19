part of 'kiosk_panels.dart';

/// Home at a glance along the bottom edge.
class KioskStatusBar extends ConsumerWidget {
  const KioskStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final s = ref.watch(dashboardSummaryProvider);
    final power = s.powerDeviceId == null
        ? null
        : ref.watch(deviceProvider(s.powerDeviceId!));
    final status = context.statusColors;
    final accents = DeviceAccents.light;

    final items = <Widget>[
      if (s.lightsTotal > 0)
        GestureDetector(
          key: const Key('kioskLights'),
          onTap: () => showAllLightsSheet(context),
          child: _StatusItem(
            icon: Icons.lightbulb,
            disc: s.lightsOn > 0
                ? accents.of(DeviceAccent.light).icon
                : GlassColors.fillStrong,
            title: l10n.kioskLightsOn(s.lightsOn),
          ),
        ),
      if (s.averageTemperature != null)
        _StatusItem(
          icon: Icons.thermostat,
          disc: GlassColors.fillStrong,
          title: l10n.kioskClimate,
          subtitle: l10n.kioskAverage(
            formatNumber(locale, s.averageTemperature!, unit: '°'),
          ),
        ),
      _StatusItem(
        icon: Icons.door_front_door_outlined,
        disc: s.openingIds.isEmpty ? GlassColors.fillStrong : status.warning,
        title: l10n.kioskDoorsWindows,
        subtitle: l10n.kioskOpenings(s.openingIds.length),
      ),
      if (power != null)
        _StatusItem(
          icon: Icons.bolt,
          disc: GlassColors.fillStrong,
          title: l10n.kioskPower,
          subtitle: DevicePresentation.sensorValue(l10n, power.state),
        ),
      if (s.criticalIds.isNotEmpty)
        _StatusItem(
          icon: Icons.warning_amber_rounded,
          disc: status.critical,
          title: l10n.summaryAlerts,
          subtitle: '${s.criticalIds.length}',
        ),
    ];
    final playing = ref.watch(nowPlayingIdProvider);
    final hasPlayers = ref.watch(
      mediaPlayerIdsProvider.select((ids) => ids.isNotEmpty),
    );
    final row = items;
    // Media stays next to Assist on the right, always visible.
    final media = playing != null
        ? _NowPlayingPill(key: const Key('kioskNowPlaying'), deviceId: playing)
        : GestureDetector(
            key: const Key('kioskMedia'),
            onTap: () => showMediaSheet(context),
            child: _StatusItem(
              icon: Icons.music_note,
              disc: const Color(0xFFB065E8),
              title: l10n.mediaTitle,
              subtitle: hasPlayers ? l10n.mediaIdle : l10n.mediaNoPlayersShort,
            ),
          );
    return Row(
      children: [
        Expanded(
          child: EdgeFade(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, w) in row.indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    w,
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Only as wide as it needs (up to a limit); the rest goes to the
        // status chips instead of being split evenly and left empty.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: media,
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: l10n.assistTitle,
          excludeSemantics: true,
          child: GestureDetector(
            key: const Key('kioskAssist'),
            onTap: () => showAssist(context),
            child: GlassPanel(
              radius: 40,
              padding: const EdgeInsets.fromLTRB(8, 8, 22, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3D7BFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assistant_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.assistTitle,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: GlassColors.text),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// What is playing, with play/pause; tap opens the player.
class _NowPlayingPill extends ConsumerWidget {
  const _NowPlayingPill({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(deviceProvider(deviceId));
    if (d == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final playing = d.state.raw == 'playing';
    final title = d.state.mediaTitle ?? d.name;
    final subtitle = d.state.mediaArtist ?? d.name;
    return Semantics(
      label: '${l10n.mediaNowPlaying}: $title, $subtitle',
      child: GestureDetector(
        onTap: () => showMediaSheet(context, playerId: d.id),
        child: GlassPanel(
          radius: 40,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MediaArtwork(
                deviceId: d.id,
                size: 44,
                radius: 22,
                background: const Color(0xFFB065E8),
                iconColor: Colors.white,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: GlassColors.text,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: GlassColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: const Key('kioskPlayPause'),
                tooltip: l10n.mediaPlayPause,
                color: GlassColors.text,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: GlassColors.muted),
                ),
                onPressed: d.supports(Capability.mediaPause)
                    ? () => runDeviceCommand(
                        context,
                        ref,
                        d,
                        const MediaPlayPause(),
                      )
                    : null,
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.icon,
    required this.disc,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final Color disc;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      radius: 40,
      padding: const EdgeInsets.fromLTRB(8, 8, 22, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: disc, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: GlassColors.text,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: GlassColors.muted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The entities picked in kiosk settings, as chips: icon, name, state and
/// when it last changed (e.g. "Washing machine · Finished · 2 min ago").
class KioskStatusChips extends ConsumerWidget {
  const KioskStatusChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(
      kioskSettingsProvider.select((s) => s.statusEntityIds),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final id in ids)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _StatusChip(key: ValueKey('chip-$id'), deviceId: id),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends ConsumerWidget {
  const _StatusChip({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(deviceProvider(deviceId));
    if (d == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = ref.watch(kioskNowProvider);
    final tone = DevicePresentation.tone(d);
    final accents = DeviceAccents.light;
    final swatch = switch (tone) {
      DeviceTone.active => accents.of(DevicePresentation.accent(d)),
      DeviceTone.warning => accents.warning,
      DeviceTone.critical => accents.critical,
      _ => null,
    };
    final changed = d.metadata.lastChanged;
    final subtitle = [
      DevicePresentation.status(l10n, d),
      if (changed != null)
        DevicePresentation.relativeTime(l10n, changed.toLocal(), now),
    ].join(' · ');

    return Semantics(
      button: true,
      label: '${d.name}, $subtitle',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.device(d.id, kiosk: true)),
        child: GlassPanel(
          radius: 40,
          padding: const EdgeInsets.fromLTRB(6, 6, 18, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: swatch?.container ?? GlassColors.fillStrong,
                ),
                child: Icon(
                  DevicePresentation.icon(d),
                  size: 22,
                  color: swatch?.icon ?? GlassColors.text,
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      d.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: GlassColors.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: GlassColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
