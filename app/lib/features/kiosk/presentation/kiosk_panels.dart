import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
import '../../weather/presentation/weather_labels.dart';
import 'glass.dart';

/// Large clock with small seconds and the date underneath.
class KioskHeaderClock extends StatefulWidget {
  const KioskHeaderClock({super.key});

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
            toBeginningOfSentenceCase(
              DateFormat.MMMMEEEEd(locale).format(_now),
              locale,
            ),
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
    if (report == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final now = report.now;
    String t(double? v) => v == null ? '—' : formatNumber(locale, v, unit: '°');
    final today = report.daily.isEmpty ? null : report.daily.first;
    final next = report.daily.skip(1).take(4).toList();

    return GlassPanel(
      key: const Key('kioskWeather'),
      child: Semantics(
        label:
            '${l10n.weatherAtHome}: ${weatherConditionLabel(l10n, now.condition)}, '
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
                    const SizedBox(width: 16),
                    Text(
                      t(now.temperature),
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: GlassColors.text,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                if (next.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final day in next)
                        SizedBox(
                          width: 76,
                          child: Column(
                            children: [
                              Text(
                                DateFormat.E(locale).format(day.date),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: GlassColors.muted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Icon(
                                weatherIcon(day.condition),
                                color: GlassColors.text,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t(day.high),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: GlassColors.text,
                                ),
                              ),
                              Text(
                                t(day.low),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: GlassColors.faint,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
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
              child: ListView(padding: EdgeInsets.zero, children: rows),
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
      child: Padding(
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
            if (summary.temperature != null) ...[
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
  const KioskShortcutsPanel({super.key, this.scrollable = true});

  final bool scrollable;

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
          if (scrollable && ids.isNotEmpty) Expanded(child: body) else body,
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
                for (final id in sceneIds)
                  Consumer(
                    builder: (context, ref, _) {
                      final d = ref.watch(deviceProvider(id));
                      if (d == null) return const SizedBox.shrink();
                      return ActionChip(
                        backgroundColor: GlassColors.fill,
                        side: const BorderSide(color: GlassColors.border),
                        avatar: const Icon(
                          Icons.play_arrow_rounded,
                          color: GlassColors.text,
                        ),
                        label: Text(
                          d.name,
                          style: const TextStyle(color: GlassColors.text),
                        ),
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
                                      content: Text(
                                        l10n.sceneActivated(d.name),
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
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
        _StatusItem(
          icon: Icons.lightbulb,
          disc: s.lightsOn > 0
              ? accents.of(DeviceAccent.light).icon
              : GlassColors.fillStrong,
          title: l10n.kioskLightsOn(s.lightsOn),
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
    return Wrap(spacing: 12, runSpacing: 12, children: items);
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: GlassColors.text,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: GlassColors.muted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
