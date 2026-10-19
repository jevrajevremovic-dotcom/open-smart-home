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

part 'kiosk_bubble_rooms.dart';
part 'kiosk_bubble_room_dialog.dart';

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
