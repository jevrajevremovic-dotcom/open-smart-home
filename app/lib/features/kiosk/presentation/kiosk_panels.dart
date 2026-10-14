import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/edge_fade.dart';
import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../dashboard/application/home_summaries.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/data/home_state_repository.dart';
import '../../devices/domain/device_command.dart';
import '../../devices/presentation/device_actions.dart';
import '../../devices/presentation/device_presentation.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../rooms/presentation/room_card.dart';
import '../../weather/application/weather_providers.dart';
import '../../weather/domain/weather.dart';
import '../../weather/presentation/weather_labels.dart';
import '../../household/application/household_providers.dart';
import '../../household/presentation/person_avatar.dart';
import '../application/kiosk_controller.dart';
import '../../calendar/presentation/calendar_browser.dart';
import '../../calendar/presentation/calendar_widgets.dart';
import '../../assist/presentation/assist_sheet.dart';
import '../../devices/domain/capability.dart';
import '../../media/application/media_providers.dart';
import '../../media/presentation/media_artwork.dart';
import '../../media/presentation/media_sheet.dart';
import '../../devices/presentation/all_lights.dart';
import 'glass.dart';

/// Large clock with small seconds and the date underneath.
class KioskHeaderClock extends StatefulWidget {
  const KioskHeaderClock({super.key, this.alignEnd = false, this.subtitle});

  final bool alignEnd;

  /// Shown after the date, e.g. the home's name.
  final String? subtitle;

  @override
  State<KioskHeaderClock> createState() => _KioskHeaderClockState();
}

class _KioskHeaderClockState extends State<KioskHeaderClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);
    return Semantics(
      label:
          '${DateFormat.Hm(locale).format(_now)}, '
          '${DateFormat.MMMMEEEEd(locale).format(_now)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: widget.alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat.Hm(locale).format(_now),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: GlassColors.text,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('ss').format(_now),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: GlassColors.faint,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              toBeginningOfSentenceCase(
                DateFormat.MMMMEEEEd(locale).format(_now),
                locale,
              ),
              ?widget.subtitle,
            ].join(' · '),
            style: theme.textTheme.titleMedium?.copyWith(
              color: GlassColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Weather at home: current conditions and the next four days.
class KioskWeatherPanel extends ConsumerWidget {
  const KioskWeatherPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(homeWeatherProvider);
    final l10n = context.l10n;
    if (report == null) {
      return GlassPanel(
        key: const Key('kioskWeatherMissing'),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: GlassColors.muted,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.kioskWeatherMissing,
                textAlign: TextAlign.center,
                style: const TextStyle(color: GlassColors.muted),
              ),
            ],
          ),
        ),
      );
    }
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final now = report.now;
    String t(double? v) => v == null ? '—' : formatNumber(locale, v, unit: '°');
    final today = report.daily.isEmpty ? null : report.daily.first;
    final next = report.daily.skip(1).take(5).toList();
    // Every second hour so six cells cover half a day.
    final hours = [
      for (final (i, h) in report.hourly.skip(1).indexed)
        if (i.isEven) h,
    ].take(6).toList();

    Widget cell(String top, IconData icon, String main, [String? sub]) =>
        SizedBox(
          width: 66,
          child: Column(
            children: [
              Text(
                top,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: GlassColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Icon(icon, color: GlassColors.text, size: 28),
              const SizedBox(height: 6),
              Text(
                main,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: GlassColors.text,
                ),
              ),
              if (sub != null)
                Text(
                  sub,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: GlassColors.faint,
                  ),
                ),
            ],
          ),
        );

    return GestureDetector(
      key: const Key('kioskWeather'),
      onTap: () => context.push(AppRoutes.weatherFor(kiosk: true)),
      child: GlassPanel(
        child: Semantics(
          button: true,
          label:
              '${l10n.weatherForecastTitle}. ${weatherConditionLabel(l10n, now.condition)}, '
              '${t(now.temperature)}',
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        weatherIcon(now.condition),
                        size: 72,
                        color: const Color(0xFF8CC8FF),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        t(now.temperature),
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: GlassColors.text,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weatherConditionLabel(l10n, now.condition),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: GlassColors.text,
                            ),
                          ),
                          if (today != null)
                            Text(
                              '↑ ${t(today.high)}   ↓ ${t(today.low)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: GlassColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (hours.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final h in hours)
                          cell(
                            DateFormat.Hm(locale).format(h.time),
                            weatherIcon(h.condition),
                            t(h.temperature),
                          ),
                      ],
                    ),
                  ],
                  if (report.source == WeatherSource.homeLocation) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.weatherMetAttribution,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: GlassColors.faint,
                      ),
                    ),
                  ],
                  if (next.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: 66.0 * math.max(hours.length, next.length),
                      height: 1,
                      color: GlassColors.border,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final day in next)
                          cell(
                            DateFormat.E(locale).format(day.date),
                            weatherIcon(day.condition),
                            t(day.high),
                            t(day.low),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rooms with lights on and temperature; tap opens the room.
class KioskRoomsPanel extends ConsumerWidget {
  const KioskRoomsPanel({super.key, this.scrollable = true});

  /// `false` inside an already scrolling page (portrait layout).
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomsProvider);
    final l10n = context.l10n;
    final rows = [
      for (var i = 0; i < rooms.length; i++) ...[
        if (i > 0) const Divider(color: GlassColors.border, height: 1),
        _RoomRow(
          roomId: rooms[i].id,
          name: rooms[i].name,
          icon: rooms[i].icon,
          colorIndex: i,
        ),
      ],
    ];
    return GlassPanel(
      key: const Key('kioskRooms'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: scrollable ? MainAxisSize.max : MainAxisSize.min,
        children: [
          GlassTitle(l10n.navRooms),
          if (scrollable)
            Expanded(
              child: EdgeFade(
                child: ListView(padding: EdgeInsets.zero, children: rows),
              ),
            )
          else
            ...rows,
        ],
      ),
    );
  }
}

/// Room icons cycle through the device accent colours so the list is easy
/// to scan; the colour carries no meaning (the name does).
const _roomColors = [
  Color(0xFF3D7BFF),
  Color(0xFFB065E8),
  Color(0xFF2DBE6C),
  Color(0xFFFF5A5F),
  Color(0xFFFFA62B),
  Color(0xFF1FB5C9),
];

class _RoomRow extends ConsumerWidget {
  const _RoomRow({
    required this.roomId,
    required this.name,
    required this.icon,
    required this.colorIndex,
  });

  final String roomId;
  final String name;
  final String? icon;
  final int colorIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summary = ref.watch(roomSummaryProvider(roomId));
    final amber = context.deviceAccents.of(DeviceAccent.light);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(AppRoutes.room(roomId, kiosk: true)),
      child: LayoutBuilder(
        builder: (context, c) {
          // Narrow panel (next to the calendar): only the lights pill.
          final compact = c.maxWidth < 300;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _roomColors[colorIndex % _roomColors.length],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(roomIcon(icon), color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: GlassColors.text,
                    ),
                  ),
                ),
                if (summary.lightsOn > 0)
                  _Pill(
                    color: amber.container,
                    foreground: amber.onContainer,
                    icon: Icons.lightbulb,
                    text: '${summary.lightsOn}',
                    semantics: l10n.roomLightsOn(summary.lightsOn),
                  ),
                if (summary.temperature != null && !compact) ...[
                  const SizedBox(width: 6),
                  _Pill(
                    color: GlassColors.fill,
                    foreground: GlassColors.text,
                    text: formatNumber(
                      l10n.localeName,
                      summary.temperature!,
                      unit: '°',
                    ),
                  ),
                ],
                if (summary.alertCount > 0) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.warning_amber_rounded,
                    color: context.statusColors.warning,
                    semanticLabel: l10n.summaryAlerts,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.color,
    required this.foreground,
    required this.text,
    this.icon,
    this.semantics,
  });

  final Color color;
  final Color foreground;
  final String text;
  final IconData? icon;
  final String? semantics;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semantics,
    excludeSemantics: semantics != null,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: foreground),
          ),
        ],
      ),
    ),
  );
}

/// Favorite devices as large glass tiles. Tap switches (or activates),
/// long press opens the device.
class KioskShortcutsPanel extends ConsumerWidget {
  const KioskShortcutsPanel({
    super.key,
    this.scrollable = true,
    this.sceneIds = const [],
  });

  final bool scrollable;

  /// Scenes shown as chips under the title (when there is no room for a
  /// separate scenes panel).
  final List<String> sceneIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ids = ref.watch(existingFavoritesProvider);
    const delegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 200,
      mainAxisExtent: 108,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
    );
    final Widget body = ids.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.kioskShortcutsEmpty,
              style: const TextStyle(color: GlassColors.muted),
            ),
          )
        : GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: !scrollable,
            physics: scrollable ? null : const NeverScrollableScrollPhysics(),
            gridDelegate: delegate,
            itemCount: ids.length,
            itemBuilder: (context, i) =>
                _ShortcutTile(key: ValueKey(ids[i]), deviceId: ids[i]),
          );
    return GlassPanel(
      key: const Key('kioskShortcuts'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: scrollable ? MainAxisSize.max : MainAxisSize.min,
        children: [
          GlassTitle(l10n.kioskShortcuts),
          if (sceneIds.isNotEmpty) ...[
            EdgeFade(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final id in sceneIds)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: KioskSceneChip(sceneId: id),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (scrollable)
            Expanded(
              child: ids.isEmpty ? SingleChildScrollView(child: body) : body,
            )
          else
            body,
        ],
      ),
    );
  }
}

class _ShortcutTile extends ConsumerStatefulWidget {
  const _ShortcutTile({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<_ShortcutTile> createState() => _ShortcutTileState();
}

class _ShortcutTileState extends ConsumerState<_ShortcutTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(deviceProvider(widget.deviceId));
    if (d == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final live = ref.watch(syncStatusProvider) == SyncStatus.live;
    final tone = DevicePresentation.tone(d);
    final accents = DeviceAccents.light; // pastel tiles read well on glass
    final swatch = switch (tone) {
      DeviceTone.active => accents.of(DevicePresentation.accent(d)),
      DeviceTone.warning => accents.warning,
      DeviceTone.critical => accents.critical,
      _ => null,
    };
    final status = DevicePresentation.status(l10n, d);

    void open() => context.push(AppRoutes.device(d.id, kiosk: true));
    Future<void> run(DeviceCommand c) async {
      setState(() => _busy = true);
      await runDeviceCommand(context, ref, d, c);
      if (mounted) setState(() => _busy = false);
    }

    final canToggle =
        d.available && live && DevicePresentation.hasQuickToggle(d);
    final canActivate =
        d.available && live && DevicePresentation.hasQuickActivate(d);
    final VoidCallback onTap = _busy
        ? () {}
        : canToggle
        ? () => run(d.state.isOn == true ? const TurnOff() : const TurnOn())
        : canActivate
        ? () => run(const Activate())
        : open;

    return Semantics(
      button: true,
      toggled: canToggle ? d.state.isOn == true : null,
      label: '${d.name}, $status',
      excludeSemantics: true,
      onLongPress: open,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: swatch?.container ?? GlassColors.fill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: swatch == null ? GlassColors.border : Colors.transparent,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            onLongPress: open,
            child: Opacity(
              opacity: d.available ? 1 : 0.55,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      DevicePresentation.icon(d),
                      size: 30,
                      color: swatch?.icon ?? GlassColors.text,
                    ),
                    const Spacer(),
                    Text(
                      d.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: swatch?.onContainer ?? GlassColors.text,
                      ),
                    ),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: swatch?.onContainer ?? GlassColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scenes as large buttons.
class KioskScenesPanel extends ConsumerWidget {
  const KioskScenesPanel({
    super.key,
    required this.sceneIds,
    this.scrollable = true,
  });

  final List<String> sceneIds;
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return GlassPanel(
      key: const Key('kioskScenes'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassTitle(l10n.scenesTitle),
          _maybeScroll(
            scrollable,
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final id in sceneIds) KioskSceneChip(sceneId: id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A scene as a glass chip; tap activates it.
class KioskSceneChip extends ConsumerWidget {
  const KioskSceneChip({super.key, required this.sceneId});

  final String sceneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final d = ref.watch(deviceProvider(sceneId));
    if (d == null) return const SizedBox.shrink();
    return ActionChip(
      backgroundColor: GlassColors.fill,
      side: const BorderSide(color: GlassColors.border),
      avatar: const Icon(Icons.play_arrow_rounded, color: GlassColors.text),
      label: Text(d.name, style: const TextStyle(color: GlassColors.text)),
      onPressed: d.available
          ? () async {
              final messenger = ScaffoldMessenger.of(context);
              if (await runDeviceCommand(context, ref, d, const Activate())) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.sceneActivated(d.name))),
                );
              }
            }
          : null,
    );
  }
}

/// Scrolls inside a fixed-height panel; plain inside a scrolling page.
Widget _maybeScroll(bool scrollable, Widget child) =>
    scrollable ? Flexible(child: SingleChildScrollView(child: child)) : child;

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

/// Current time, refreshed every 30 s, for "… minutes ago" labels.
final kioskNowProvider = Provider<DateTime>((ref) {
  final timer = Timer(const Duration(seconds: 30), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return DateTime.now();
});

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

/// Household members' avatars.
class KioskPeople extends ConsumerWidget {
  const KioskPeople({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(peopleIdsProvider);
    if (ids.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: context.l10n.householdTitle,
      child: Row(
        key: const Key('kioskPeople'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final id in ids.take(6))
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: PersonAvatar(personId: id, size: 48),
            ),
        ],
      ),
    );
  }
}

/// Agenda and month of the Home Assistant calendars.
class KioskCalendarPanel extends ConsumerWidget {
  const KioskCalendarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.l10n.localeName;
    return GlassPanel(
      key: const Key('kioskCalendar'),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
      child: CalendarBrowser(
        palette: CalendarPalette.glass,
        fitGrid: true,
        header: GlassTitle(
          toBeginningOfSentenceCase(
            DateFormat.MMMMEEEEd(locale).format(ref.watch(kioskNowProvider)),
            locale,
          ),
        ),
      ),
    );
  }
}
