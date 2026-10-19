import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../assist/presentation/assist_sheet.dart';
import '../../authentication/application/session_controller.dart';
import '../../clap/clap_listener.dart';
import '../../dashboard/application/home_sentence.dart';
import '../../dashboard/application/home_summaries.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/domain/capability.dart';
import '../../devices/domain/device_command.dart';
import '../../devices/domain/device_kind.dart';
import '../../devices/domain/smart_home_device.dart';
import '../../devices/presentation/all_lights.dart';
import '../../devices/presentation/device_actions.dart';
import '../../devices/presentation/device_presentation.dart';
import '../../household/family_messages.dart';
import '../../media/application/media_providers.dart';
import '../../media/presentation/media_sheet.dart';
import '../../notifications/application/notifications_provider.dart';
import '../../notifications/presentation/notifications.dart';
import '../../dashboard/presentation/dashboard_screen.dart'
    show ConnectionIndicator;
import '../../rooms/presentation/room_card.dart' show roomColor, roomIcon;
import '../../timers/kiosk_timers.dart';
import '../../weather/application/weather_providers.dart';
import '../../weather/domain/weather.dart';
import '../../weather/presentation/weather_labels.dart';
import '../application/kiosk_controller.dart';
import 'glass.dart';
import 'kiosk_alarm.dart';
import 'kiosk_leaving.dart';
import 'kiosk_layout_view.dart';
import 'kiosk_panels.dart';
import 'pin_dialog.dart';

String _greeting(AppLocalizations l10n, DateTime now) => switch (now.hour) {
  >= 5 && < 12 => l10n.greetingMorning,
  >= 12 && < 18 => l10n.greetingAfternoon,
  >= 18 && < 23 => l10n.greetingEvening,
  _ => l10n.greetingNight,
};

/// Bubble style header: greeting and the home sentence on the left, small
/// round chips on the right, a row of key numbers below.
class KioskBubbleHeader extends ConsumerWidget {
  const KioskBubbleHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = ref.watch(kioskNowProvider);
    final sentence = ref.watch(homeSentenceProvider(l10n));
    // Short wall tablets (1280×800): a smaller greeting leaves the panels
    // their room.
    final short = MediaQuery.sizeOf(context).height < 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(l10n, now),
                    style:
                        (short
                                ? theme.textTheme.headlineMedium
                                : theme.textTheme.displaySmall)
                            ?.copyWith(
                              color: GlassColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  SizedBox(height: short ? 4 : 8),
                  Text(
                    sentence,
                    key: const Key('kioskHomeSentence'),
                    maxLines: short ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: GlassColors.muted,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            const _Chips(),
          ],
        ),
        SizedBox(height: short ? 12 : 20),
        const _Stats(),
        // Entities the household chose to see on the wall.
        if (ref.watch(
          kioskSettingsProvider.select((s) => s.statusEntityIds.isNotEmpty),
        )) ...[
          const SizedBox(height: 14),
          const KioskStatusChips(),
        ],
      ],
    );
  }
}

/// Small round buttons with a number: lights, open things, messages,
/// music, Assist, household, edit, exit.
class _Chips extends ConsumerWidget {
  const _Chips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(dashboardSummaryProvider);
    // Household messages have their own button.
    final notifications = ref.watch(
      haNotificationsProvider.select(
        (n) => (n.value ?? const [])
            .where((x) => !x.id.startsWith(FamilyMessage.prefix))
            .length,
      ),
    );
    final messages = ref.watch(familyMessagesProvider.select((m) => m.length));
    final playing = ref.watch(nowPlayingIdProvider);
    final connected = ref.watch(
      connectionStatusProvider.select((s) => s.value?.isConnected ?? false),
    );
    final amber = DeviceAccents.light.of(DeviceAccent.light);
    final warning = DeviceAccents.light.warning;
    final alarm = ref.watch(kioskAlarmProvider);
    final alarmState = alarm?.state.alarmState;
    final armed = alarmState != null && alarmState != AlarmState.disarmed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            if (!connected) const ConnectionIndicator(),
            if (s.lightsTotal > 0)
              _Chip(
                key: const Key('kioskLights'),
                icon: Icons.lightbulb_outline,
                text: '${s.lightsOn}',
                tooltip: l10n.kioskLightsOn(s.lightsOn),
                highlight: s.lightsOn > 0 ? amber : null,
                onTap: () => showAllLightsSheet(context),
              ),
            if (s.openingIds.isNotEmpty)
              _Chip(
                icon: Icons.sensor_door_outlined,
                text: '${s.openingIds.length}',
                tooltip: l10n.kioskOpenings(s.openingIds.length),
                highlight: warning,
              ),
            if (notifications > 0)
              _Chip(
                key: const Key('kioskNotifications'),
                icon: Icons.notifications_outlined,
                text: '$notifications',
                tooltip: l10n.notificationsCount(notifications),
                highlight: warning,
                onTap: () => showNotificationsSheet(context),
              ),
            _Chip(
              key: const Key('kioskMessages'),
              icon: Icons.forum_outlined,
              text: messages > 0 ? '$messages' : null,
              tooltip: l10n.familyMessages,
              highlight: messages > 0
                  ? DeviceAccents.light.of(DeviceAccent.cool)
                  : null,
              onTap: () => showFamilyMessages(context),
            ),
            _Chip(
              key: Key(playing == null ? 'kioskMedia' : 'kioskNowPlaying'),
              icon: playing == null
                  ? Icons.music_note_outlined
                  : Icons.graphic_eq,
              tooltip: l10n.mediaTitle,
              highlight: playing == null
                  ? null
                  : DeviceAccents.light.of(DeviceAccent.media),
              onTap: () => showMediaSheet(context, playerId: playing),
            ),
            if (alarm != null)
              _Chip(
                key: const Key('kioskAlarm'),
                icon: armed ? Icons.shield : Icons.shield_outlined,
                tooltip: DevicePresentation.status(l10n, alarm),
                highlight: alarmState == AlarmState.triggered
                    ? warning
                    : armed
                    ? DeviceAccents.light.of(DeviceAccent.cool)
                    : null,
                onTap: () => showKioskAlarm(context),
              ),
            _Chip(
              key: const Key('kioskLeaving'),
              icon: Icons.directions_walk,
              tooltip: l10n.kioskLeaving,
              onTap: () => showKioskLeaving(context),
            ),
            _Chip(
              key: const Key('kioskTimer'),
              icon: Icons.timer_outlined,
              tooltip: l10n.timerTitle,
              onTap: () => showTimerPicker(context, ref),
            ),
            _Chip(
              key: const Key('kioskAssist'),
              icon: Icons.assistant_outlined,
              tooltip: l10n.assistTitle,
              onTap: () => showAssist(context),
            ),
            _Chip(
              key: const Key('kioskEditLayout'),
              icon: Icons.dashboard_customize_outlined,
              tooltip: l10n.kioskEditLayout,
              onTap: () async {
                if (await unlockKioskEditing(context, ref)) {
                  ref.read(kioskEditingProvider.notifier).set(true);
                }
              },
            ),
            _Chip(
              key: const Key('kioskExit'),
              icon: Icons.lock_outline,
              tooltip: l10n.kioskExit,
              onTap: () async {
                if (await showKioskExitDialog(context, ref) &&
                    context.mounted) {
                  context.go(AppRoutes.home);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        const KioskPeople(),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.icon,
    required this.tooltip,
    this.text,
    this.highlight,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final String? text;

  /// Pastel fill when it needs attention or something is on.
  final AccentSwatch? highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = highlight?.onContainer ?? GlassColors.text;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: highlight?.container ?? BubbleColors.card,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: text == null ? 12 : 14,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: fg, semanticLabel: tooltip),
                if (text != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    text!,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: fg),
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

/// Key numbers in one line: weather, inside, humidity, power, open.
class _Stats extends ConsumerWidget {
  const _Stats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final s = ref.watch(dashboardSummaryProvider);
    final report = ref.watch(homeWeatherProvider);
    final weather = report?.now;
    final power = s.powerDeviceId == null
        ? null
        : ref.watch(deviceProvider(s.powerDeviceId!));
    final items = <Widget>[
      if (weather?.temperature != null)
        _Stat(
          key: const Key('kioskWeather'),
          icon: weatherIcon(weather!.condition),
          label: weatherConditionLabel(l10n, weather.condition),
          value: formatNumber(locale, weather.temperature!, unit: '°'),
          // MET Norway data is CC BY 4.0: credit it wherever it shows.
          caption: report!.source == WeatherSource.home
              ? null
              : l10n.weatherMetAttribution,
          onTap: () => context.push(AppRoutes.weatherFor(kiosk: true)),
        ),
      if (s.averageTemperature != null)
        _Stat(
          icon: Icons.thermostat,
          label: l10n.kioskStatInside,
          value: formatNumber(locale, s.averageTemperature!, unit: '°'),
        ),
      if (s.averageHumidity != null)
        _Stat(
          icon: Icons.water_drop_outlined,
          label: l10n.kioskStatHumidity,
          value: formatNumber(locale, s.averageHumidity!, unit: '%'),
        ),
      if (power != null)
        _Stat(
          icon: Icons.bolt,
          label: l10n.kioskStatPower,
          value: DevicePresentation.sensorValue(l10n, power.state),
        ),
      _Stat(
        icon: Icons.door_front_door_outlined,
        label: l10n.kioskStatOpenings,
        value: s.openingIds.isEmpty
            ? l10n.summaryOpeningsClosed
            : l10n.summaryOpeningsOpen(s.openingIds.length),
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, w) in items.indexed) ...[
            if (i > 0) const SizedBox(width: 32),
            w,
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: GlassColors.muted, size: 26),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: GlassColors.faint,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: GlassColors.text,
                  ),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: GlassColors.faint,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Rooms as large bubbles: big temperature, a round icon; a room where
/// something is on turns pastel. Tap opens the room's devices.
class KioskBubbleRoomsPanel extends ConsumerWidget {
  const KioskBubbleRoomsPanel({super.key, this.scrollable = true});

  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rooms = ref.watch(roomsProvider);
    final title = Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        children: [
          const Icon(Icons.meeting_room_outlined, color: GlassColors.muted),
          const SizedBox(width: 8),
          Text(
            l10n.navRooms,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: GlassColors.text),
          ),
        ],
      ),
    );
    final grid = LayoutBuilder(
      builder: (context, c) {
        final columns = (c.maxWidth / 200).floor().clamp(1, 5);
        final width = (c.maxWidth - 12 * (columns - 1)) / columns;
        // Two rows fill a fixed-height panel; otherwise a pleasant shape.
        final height = scrollable && c.maxHeight.isFinite
            ? ((c.maxHeight - 12) / 2).clamp(110.0, width)
            : width / 1.25;
        return GridView.builder(
          key: const Key('kioskRooms'),
          padding: EdgeInsets.zero,
          shrinkWrap: !scrollable,
          physics: scrollable ? null : const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: width / height,
          ),
          itemCount: rooms.length,
          itemBuilder: (_, i) => _RoomBubble(
            roomId: rooms[i].id,
            name: rooms[i].name,
            icon: rooms[i].icon,
          ),
        );
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: scrollable ? MainAxisSize.max : MainAxisSize.min,
      children: [
        title,
        if (scrollable) Expanded(child: grid) else grid,
      ],
    );
  }
}

class _RoomBubble extends ConsumerWidget {
  const _RoomBubble({required this.roomId, required this.name, this.icon});

  final String roomId;
  final String name;
  final String? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summary = ref.watch(roomSummaryProvider(roomId));
    // Same colour per room as on the phone; lights on show as a pill.
    final color = roomColor(icon, name);
    final pastel = DeviceAccents.light.of(DeviceAccent.light);
    const fg = GlassColors.text;
    const sub = GlassColors.faint;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(BubbleColors.card, color, 0.18)!,
            Color.lerp(BubbleColors.card, color, 0.40)!,
          ],
        ),
      ),
      child: Material(
        key: ValueKey('kioskRoom-$roomId'),
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showBubbleRoom(context, roomId: roomId, name: name),
          onLongPress: () => context.push(AppRoutes.room(roomId, kiosk: true)),
          child: LayoutBuilder(
            builder: (context, c) {
              // Short cells (many rooms in a low panel): smaller icon and type.
              final compact = c.maxHeight < 150;
              return Stack(
                children: [
                  Positioned(
                    right: -12,
                    bottom: -16,
                    child: Icon(
                      roomIcon(icon),
                      size: compact ? 84 : 120,
                      color: color.withValues(alpha: 0.32),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(compact ? 14 : 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: compact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: fg,
                                ),
                              ),
                            ),
                            if (summary.lightsOn > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                key: ValueKey('kioskRoomLights-$roomId'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: pastel.container,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lightbulb,
                                      size: 16,
                                      color: pastel.onContainer,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${summary.lightsOn}',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(color: pastel.onContainer),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Whatever room is left: the value shrinks rather than
                        // overflow (large system text, short cells).
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.bottomLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    summary.temperature == null
                                        ? (summary.lightsOn > 0
                                              ? l10n.roomLightsOn(
                                                  summary.lightsOn,
                                                )
                                              : l10n.roomDevicesCount(
                                                  summary.deviceCount,
                                                ))
                                        : formatNumber(
                                            l10n.localeName,
                                            summary.temperature!,
                                            unit: '°',
                                          ),
                                    maxLines: 1,
                                    style: summary.temperature == null
                                        ? theme.textTheme.titleSmall?.copyWith(
                                            color: fg,
                                          )
                                        : (compact
                                                  ? theme
                                                        .textTheme
                                                        .headlineMedium
                                                  : theme
                                                        .textTheme
                                                        .displaySmall)
                                              ?.copyWith(
                                                color: fg,
                                                fontWeight: FontWeight.w500,
                                              ),
                                  ),
                                  if (summary.humidity != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      formatNumber(
                                        l10n.localeName,
                                        summary.humidity!,
                                        unit: '%',
                                      ),
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(color: sub),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A room's devices in a window over the kiosk: climate first, lights as
/// coloured cards with the brightness slider inside, then the rest.
Future<void> showBubbleRoom(
  BuildContext context, {
  required String roomId,
  required String name,
}) => showDialog<void>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: 0.6),
  builder: (_) => _BubbleRoomDialog(roomId: roomId, name: name),
);

class _BubbleRoomDialog extends ConsumerWidget {
  const _BubbleRoomDialog({required this.roomId, required this.name});

  final String roomId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final ids =
        ref.watch(deviceIdsByRoomProvider)[roomId]?.toList() ?? const [];
    final devices = [for (final id in ids) ?ref.watch(deviceProvider(id))]
        .where((d) => !d.isAuxiliary)
        .toList();
    final climate = [
      for (final d in devices)
        if (d.kind == DeviceKind.climate || d.kind == DeviceKind.thermostat) d,
    ];
    final lights = [
      for (final d in devices)
        if (d.kind.isLight) d,
    ];
    final other = [
      for (final d in devices)
        if (!climate.contains(d) && !lights.contains(d) && !d.kind.isSensor) d,
    ];
    Widget section(String title, List<Widget> cards) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: GlassColors.text,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= 520 ? 2 : 1;
            final w = (c.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final card in cards) SizedBox(width: w, child: card),
              ],
            );
          },
        ),
      ],
    );
    return Dialog(
      key: const Key('kioskRoomSheet'),
      backgroundColor: BubbleColors.background,
      insetPadding: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: GlassColors.text,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('kioskRoomOpenFull'),
                  tooltip: l10n.allDevices,
                  color: GlassColors.muted,
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.room(roomId, kiosk: true));
                  },
                  icon: const Icon(Icons.open_in_full),
                ),
                IconButton(
                  key: const Key('kioskRoomClose'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  color: GlassColors.text,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (climate.isNotEmpty)
              section(l10n.groupClimate, [
                for (final d in climate)
                  _ClimateBubble(device: d, roomName: name),
              ]),
            if (lights.isNotEmpty)
              section(l10n.groupLights, [
                for (final d in lights)
                  BubbleLightCard(device: d, roomName: name),
              ]),
            if (other.isNotEmpty)
              section(l10n.groupOther, [
                for (final d in other) _DeviceBubble(device: d, roomName: name),
              ]),
          ],
        ),
      ),
    );
  }
}

/// A light as a coloured card: brightness in big type, a round on/off
/// button, and the brightness slider across the bottom of the card.
class BubbleLightCard extends ConsumerStatefulWidget {
  const BubbleLightCard({super.key, required this.device, this.roomName});

  final SmartHomeDevice device;

  /// Left out in front of the device name.
  final String? roomName;

  @override
  ConsumerState<BubbleLightCard> createState() => _BubbleLightCardState();
}

class _BubbleLightCardState extends ConsumerState<BubbleLightCard> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final d = ref.watch(deviceProvider(widget.device.id)) ?? widget.device;
    final on = d.state.isOn == true;
    final dimmable = d.supports(Capability.brightness);
    final percent = _dragging?.round() ?? d.state.brightnessPercent;
    final pastel = DeviceAccents.light.of(DeviceAccent.light);
    final bg = on ? pastel.container : BubbleColors.card;
    final fg = on ? pastel.onContainer : GlassColors.text;
    return Material(
      key: ValueKey('bubbleLight-${d.id}'),
      color: bg,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: d.available
            ? () => runDeviceCommand(context, ref, d, const Toggle())
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          on && dimmable && percent != null
                              ? '$percent %'
                              : (on ? l10n.stateOn : l10n.stateOff),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DevicePresentation.shortName(d.name, widget.roomName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: on ? pastel.onContainer : Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      on ? Icons.lightbulb : Icons.lightbulb_outline,
                      color: on ? pastel.container : Colors.white,
                    ),
                  ),
                ],
              ),
              if (dimmable)
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 14,
                    activeTrackColor: on
                        ? pastel.onContainer.withValues(alpha: 0.85)
                        : GlassColors.faint,
                    inactiveTrackColor: on
                        ? Colors.white.withValues(alpha: 0.7)
                        : BubbleColors.raised,
                    thumbColor: on ? pastel.onContainer : Colors.white,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    key: ValueKey('bubbleLightSlider-${d.id}'),
                    value: (percent ?? 0).toDouble().clamp(0, 100),
                    max: 100,
                    label: '${percent ?? 0} %',
                    onChanged: d.available
                        ? (v) => setState(() => _dragging = v)
                        : null,
                    onChangeEnd: (v) async {
                      final value = v.round().clamp(1, 100);
                      await runDeviceCommand(
                        context,
                        ref,
                        d,
                        SetBrightness(value),
                      );
                      if (mounted) setState(() => _dragging = null);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClimateBubble extends ConsumerWidget {
  const _ClimateBubble({required this.device, this.roomName});

  final SmartHomeDevice device;
  final String? roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final d = ref.watch(deviceProvider(device.id)) ?? device;
    final target = d.state.targetTemperature;
    final step = d.limits.temperatureStep ?? 0.5;
    final current = d.state.currentTemperature;
    Widget button(String key, IconData icon, double delta) => IconButton.filled(
      key: ValueKey('$key-${d.id}'),
      style: IconButton.styleFrom(
        backgroundColor: BubbleColors.raised,
        foregroundColor: GlassColors.text,
      ),
      onPressed: target == null || !d.available
          ? null
          : () => runDeviceCommand(
              context,
              ref,
              d,
              SetTargetTemperature(target + delta),
            ),
      icon: Icon(icon),
    );
    return Material(
      color: BubbleColors.card,
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
        child: Row(
          children: [
            Icon(
              DevicePresentation.icon(d),
              color: DeviceAccents.light.of(DeviceAccent.heat).container,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DevicePresentation.shortName(d.name, roomName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: GlassColors.text,
                    ),
                  ),
                  Text(
                    [
                      DevicePresentation.status(l10n, d),
                      if (current != null)
                        formatNumber(l10n.localeName, current, unit: '°'),
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: GlassColors.faint,
                    ),
                  ),
                ],
              ),
            ),
            button('bubbleClimateDown', Icons.remove, -step),
            SizedBox(
              width: 64,
              child: Text(
                target == null
                    ? '—'
                    : formatNumber(l10n.localeName, target, unit: '°'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: GlassColors.text,
                ),
              ),
            ),
            button('bubbleClimateUp', Icons.add, step),
          ],
        ),
      ),
    );
  }
}

class _DeviceBubble extends ConsumerWidget {
  const _DeviceBubble({required this.device, this.roomName});

  final SmartHomeDevice device;
  final String? roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final d = ref.watch(deviceProvider(device.id)) ?? device;
    final active = d.state.isOn == true || d.state.isActive == true;
    final accent = DeviceAccents.light.of(DevicePresentation.accent(d));
    final bg = active ? accent.container : BubbleColors.card;
    final fg = active ? accent.onContainer : GlassColors.text;
    final command = clapCommandFor(d);
    return Material(
      key: ValueKey('bubbleDevice-${d.id}'),
      color: bg,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: command == null || !d.available
            ? () => context.push(AppRoutes.device(d.id, kiosk: true))
            : () => runDeviceCommand(context, ref, d, command),
        onLongPress: () => context.push(AppRoutes.device(d.id, kiosk: true)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: active ? accent.onContainer : Colors.black,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  DevicePresentation.icon(d),
                  color: active ? accent.container : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DevicePresentation.shortName(d.name, roomName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(color: fg),
                    ),
                    Text(
                      DevicePresentation.status(l10n, d),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: fg),
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
