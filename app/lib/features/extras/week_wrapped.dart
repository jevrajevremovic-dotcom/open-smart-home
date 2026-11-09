import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/localization/l10n.dart';
import '../../app/theme/app_theme.dart';
import '../../core/storage/app_preferences.dart';
import '../../integrations/home_assistant/models/ha_history.dart';
import '../authentication/application/session_controller.dart';
import '../devices/application/device_providers.dart';
import '../devices/domain/device_kind.dart';
import '../devices/domain/smart_home_device.dart';
import '../energy/application/energy_providers.dart';
import '../energy/data/energy_repository.dart';
import '../kiosk/presentation/kiosk_motion.dart';

/// A week in the home, counted from Home Assistant's logbook.
@immutable
class WeekStats {
  const WeekStats({
    this.doorOpenings = 0,
    this.topDoor,
    this.lightsOn = 0,
    this.topLight,
    this.topLightCount = 0,
    this.arrivals = const {},
    this.unlocks = 0,
    this.busiestDay,
    this.thisWeekKwh,
    this.lastWeekKwh,
    this.doorbell = 0,
    this.longestOpen,
  });

  final int doorOpenings;
  final String? topDoor;
  final int lightsOn;
  final String? topLight;
  final int topLightCount;

  /// Times each person came home, by name.
  final Map<String, int> arrivals;
  final int unlocks;

  /// 1 = Monday … 7 = Sunday.
  final int? busiestDay;

  /// Electricity this week (Monday until now) and the whole last week.
  final double? thisWeekKwh;
  final double? lastWeekKwh;

  /// Times the doorbell rang.
  final int doorbell;

  /// The door or window left open longest (at least half an hour), or
  /// the light left on longest (at least eight hours): name and how long.
  final (String, Duration, bool light)? longestOpen;

  bool get isEmpty =>
      doorOpenings == 0 &&
      lightsOn == 0 &&
      arrivals.isEmpty &&
      unlocks == 0 &&
      doorbell == 0;

  WeekStats withEnergy(double? thisWeek, double? lastWeek) => WeekStats(
    doorOpenings: doorOpenings,
    topDoor: topDoor,
    lightsOn: lightsOn,
    topLight: topLight,
    topLightCount: topLightCount,
    arrivals: arrivals,
    unlocks: unlocks,
    busiestDay: busiestDay,
    thisWeekKwh: thisWeek,
    lastWeekKwh: lastWeek,
    doorbell: doorbell,
    longestOpen: longestOpen,
  );
}

const _doorClasses = {'door', 'garage_door', 'window', 'opening'};

/// Counts the week from logbook [entries]; [devices] tells what each
/// entity is. Only what Home Assistant recorded; nothing is estimated.
WeekStats weekStats(
  List<HaLogbookEntry> entries,
  Map<String, SmartHomeDevice> devices,
) {
  final doors = <String, int>{};
  final lights = <String, int>{};
  final arrivals = <String, int>{};
  final days = <int, int>{};
  var unlocks = 0;
  var doorbell = 0;
  // Since when each door/light is open/on, walking forward in time.
  final since = <String, DateTime>{};
  (String, Duration, bool)? longestDoor;
  (String, Duration, bool)? longestLight;
  for (final e in [...entries]..sort((a, b) => a.when.compareTo(b.when))) {
    final id = e.entityId;
    if (id == null) continue;
    final d = devices[id];
    final isLight = id.startsWith('light.');
    final isDoor =
        id.startsWith('binary_sensor.') &&
        _doorClasses.contains(d?.metadata.haDeviceClass);
    if (!isLight && !isDoor) continue;
    if (e.state == 'on') {
      since.putIfAbsent(id, () => e.when);
    } else if (since.remove(id) case final from?) {
      final open = e.when.difference(from);
      final name = d?.name ?? e.name ?? id;
      if (isLight && open > (longestLight?.$2 ?? const Duration(hours: 8))) {
        longestLight = (name, open, true);
      }
      if (isDoor && open > (longestDoor?.$2 ?? const Duration(minutes: 30))) {
        longestDoor = (name, open, false);
      }
    }
  }
  for (final e in entries) {
    final id = e.entityId;
    if (id == null) continue;
    final d = devices[id];
    final name = d?.name ?? e.name ?? id;
    days.update(e.when.weekday, (v) => v + 1, ifAbsent: () => 1);
    if (id.startsWith('light.') && e.state == 'on') {
      lights.update(name, (v) => v + 1, ifAbsent: () => 1);
    } else if (id.startsWith('binary_sensor.') &&
        e.state == 'on' &&
        _doorClasses.contains(d?.metadata.haDeviceClass)) {
      doors.update(name, (v) => v + 1, ifAbsent: () => 1);
    } else if (id.startsWith('person.') && e.state == 'home') {
      arrivals.update(name, (v) => v + 1, ifAbsent: () => 1);
    } else if (id.startsWith('lock.') && e.state == 'unlocked') {
      unlocks++;
    } else if (d?.kind == DeviceKind.doorbell ||
        (id.startsWith('binary_sensor.') &&
            e.state == 'on' &&
            id.contains('doorbell'))) {
      doorbell++;
    }
  }
  MapEntry<String, int>? top(Map<String, int> m) => m.entries.isEmpty
      ? null
      : m.entries.reduce((a, b) => b.value > a.value ? b : a);
  final topLight = top(lights);
  return WeekStats(
    doorOpenings: doors.values.fold(0, (a, b) => a + b),
    topDoor: top(doors)?.key,
    lightsOn: lights.values.fold(0, (a, b) => a + b),
    topLight: topLight?.key,
    topLightCount: topLight?.value ?? 0,
    arrivals: arrivals,
    unlocks: unlocks,
    busiestDay: days.entries.isEmpty
        ? null
        : days.entries.reduce((a, b) => b.value > a.value ? b : a).key,
    doorbell: doorbell,
    // A door left open matters more than a light left on.
    longestOpen: longestDoor ?? longestLight,
  );
}

/// The last 7 days, plus electricity when Energy is set up.
final weekStatsProvider = FutureProvider.autoDispose<WeekStats>((ref) async {
  final api = ref.watch(homeAssistantApiProvider);
  if (api == null) return const WeekStats();
  final now = DateTime.now();
  final entries = await api.fetchLogbook(
    null,
    now.subtract(const Duration(days: 7)),
    now,
  );
  final stats = weekStats(entries, ref.read(homeSnapshotProvider).devices);
  try {
    final prefs = await ref.read(energyPrefsProvider.future);
    final repository = ref.read(energyRepositoryProvider);
    if (prefs == null || repository == null || !prefs.hasElectricity) {
      return stats;
    }
    final thisWeek = await repository.loadReport(
      prefs,
      EnergyRange.week,
      now: now,
    );
    final (monday, _) = EnergyRange.week.bounds(now);
    final lastWeek = await repository.loadReport(
      prefs,
      EnergyRange.week,
      now: monday.subtract(const Duration(minutes: 1)),
    );
    return stats.withEnergy(thisWeek.consumption, lastWeek.consumption);
  } on Object {
    // Energy is optional: the week without it.
    return stats;
  }
});

Future<void> showWeekWrapped(BuildContext context) => showDialog<void>(
  context: context,
  useSafeArea: false,
  builder: (_) => Theme(data: AppTheme.dark(), child: const _WrappedScreen()),
);

/// One card of the story.
typedef _Story = ({String emoji, String title, num? value, String? caption});

class _WrappedScreen extends ConsumerStatefulWidget {
  const _WrappedScreen();

  @override
  ConsumerState<_WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends ConsumerState<_WrappedScreen> {
  final _pages = PageController();
  int _page = 0;

  static const _hues = [265.0, 20.0, 190.0, 330.0, 140.0, 45.0, 220.0];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<_Story> _stories(BuildContext context, WeekStats s) {
    final l10n = context.l10n;
    final topArrival = s.arrivals.entries.isEmpty
        ? null
        : s.arrivals.entries.reduce((a, b) => b.value > a.value ? b : a);
    return [
      (
        emoji: '🏡',
        title: l10n.wrappedIntro,
        value: null,
        caption: l10n.wrappedIntroCaption,
      ),
      if (s.doorOpenings > 0)
        (
          emoji: '🚪',
          title: l10n.wrappedDoors,
          value: s.doorOpenings,
          caption: s.topDoor == null ? null : l10n.wrappedTopDoor(s.topDoor!),
        ),
      if (s.lightsOn > 0)
        (
          emoji: '💡',
          title: l10n.wrappedLights,
          value: s.lightsOn,
          caption: s.topLight == null
              ? null
              : l10n.wrappedTopLight(s.topLight!, s.topLightCount),
        ),
      if (topArrival != null)
        (
          emoji: '👋',
          title: l10n.wrappedArrivals,
          value: s.arrivals.values.fold<int>(0, (a, b) => a + b),
          caption: l10n.wrappedTopArrival(topArrival.key, topArrival.value),
        ),
      if (s.unlocks > 0)
        (
          emoji: '🔑',
          title: l10n.wrappedUnlocks,
          value: s.unlocks,
          caption: null,
        ),
      if (s.doorbell > 0)
        (
          emoji: '🔔',
          title: l10n.wrappedDoorbell,
          value: s.doorbell,
          caption: null,
        ),
      if (s.longestOpen case (final name, final open, final light))
        (
          emoji: light ? '🕯️' : '🪟',
          title: light ? l10n.wrappedLongestOn : l10n.wrappedLongestOpen,
          value: null,
          caption: '$name · ${wrappedDuration(l10n, open)}',
        ),
      if (s.busiestDay != null)
        (
          emoji: '📅',
          title: l10n.wrappedBusiestDay,
          value: null,
          caption: _weekdayName(l10n.localeName, s.busiestDay!),
        ),
      if (s.thisWeekKwh != null)
        (
          emoji: '⚡',
          title: l10n.wrappedEnergy,
          value: double.parse(s.thisWeekKwh!.toStringAsFixed(1)),
          caption: s.lastWeekKwh == null
              ? l10n.wrappedEnergyUnit
              : l10n.wrappedEnergyLastWeek(s.lastWeekKwh!.toStringAsFixed(1)),
        ),
      (
        emoji: '✨',
        title: l10n.wrappedOutro,
        value: null,
        caption: l10n.wrappedOutroCaption,
      ),
    ];
  }

  /// The weekday's full name in the app's language (1 = Monday).
  static String _weekdayName(String locale, int weekday) =>
      // 2024-01-01 was a Monday.
      DateFormat.EEEE(locale).format(DateTime(2024, 1, weekday));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = ref.watch(weekStatsProvider);
    final moving = kioskMotion(context, ref);
    return Material(
      key: const Key('wrappedScreen'),
      color: Colors.black,
      child: SafeArea(
        child: stats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _Closing(text: l10n.wrappedUnavailable),
          data: (s) {
            if (s.isEmpty && s.thisWeekKwh == null) {
              return _Closing(text: l10n.wrappedEmpty);
            }
            final stories = _stories(context, s);
            return Stack(
              children: [
                PageView(
                  key: const Key('wrappedPages'),
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    for (final (i, story) in stories.indexed)
                      _StoryCard(
                        story: story,
                        hue: _hues[i % _hues.length],
                        active: i == _page,
                        moving: moving,
                      ),
                  ],
                ),
                // Where we are in the story.
                Positioned(
                  top: 12,
                  left: 16,
                  right: 56,
                  child: Row(
                    children: [
                      for (var i = 0; i < stories.length; i++)
                        Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: i <= _page ? 0.9 : 0.25,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 4,
                  child: IconButton(
                    key: const Key('wrappedClose'),
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                // Tap the right half for the next card, the left for back.
                Positioned.fill(
                  top: 56,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => _pages.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          key: const Key('wrappedNext'),
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (_page == stories.length - 1) {
                              Navigator.of(context).pop();
                            } else {
                              _pages.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          },
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
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.hue,
    required this.active,
    required this.moving,
  });

  final _Story story;
  final double hue;
  final bool active;
  final bool moving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = story.value;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSVColor.fromAHSV(1, hue, 0.65, 0.45).toColor(),
            HSVColor.fromAHSV(1, (hue + 40) % 360, 0.7, 0.18).toColor(),
          ],
        ),
      ),
      // Very large text scrolls instead of spilling off the card.
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: AnimatedScale(
            scale: active || !moving ? 1 : 0.9,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(story.emoji, style: const TextStyle(fontSize: 72)),
                const SizedBox(height: 24),
                Text(
                  story.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 16),
                  // Counts up each time its card comes into view.
                  active
                      ? CountUpText(
                          key: const Key('wrappedValue'),
                          value: value.toDouble(),
                          format: (v) => value is int
                              ? v.round().toString()
                              : v.toStringAsFixed(1),
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : Text(
                          '$value',
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ],
                if (story.caption != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    story.caption!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
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

class _Closing extends StatelessWidget {
  const _Closing({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    ),
  );
}

/// "3 h 20 min", "2 days 4 h".
String wrappedDuration(AppLocalizations l10n, Duration d) {
  if (d.inDays >= 1) return l10n.wrappedDays(d.inDays, d.inHours % 24);
  return l10n.wrappedHours(d.inHours, d.inMinutes % 60);
}

/// Payload of the weekly notification (opens the week's story).
const weekReportPayload = 'osh:week';

/// When this week's summary is due: the last Sunday 19:00 not after [now].
DateTime weekReportDue(DateTime now) {
  final sunday = DateTime(now.year, now.month, now.day - now.weekday % 7, 19);
  return sunday.isAfter(now)
      ? sunday.subtract(const Duration(days: 7))
      : sunday;
}

/// Time to notify: past Sunday 19:00 (until Tuesday), not yet sent.
bool weekReportPending(DateTime now, DateTime? lastSent) {
  final due = weekReportDue(now);
  return now.difference(due) < const Duration(days: 2) &&
      (lastSent == null || lastSent.isBefore(due));
}

/// One line for the notification: "Doors 34× · lights 51× · …".
String weekReportBody(AppLocalizations l10n, WeekStats s) => [
  if (s.doorOpenings > 0) l10n.weekReportDoors(s.doorOpenings),
  if (s.lightsOn > 0) l10n.weekReportLights(s.lightsOn),
  if (s.doorbell > 0) l10n.weekReportDoorbell(s.doorbell),
  if (s.longestOpen case (final name, final open, _))
    l10n.weekReportLongest(name, wrappedDuration(l10n, open)),
  if (s.thisWeekKwh != null)
    l10n.weekReportEnergy(s.thisWeekKwh!.toStringAsFixed(1)),
].join(' · ');

/// The week as a notification on Sunday evening (opt-in). Remembers when
/// it was last sent, so each week comes once.
class WeekReportController extends Notifier<bool> {
  static const _key = 'week.notify';

  @override
  bool build() =>
      ref.watch(appPreferencesProvider).readJson(_key)?['enabled'] == true;

  DateTime? get lastSent => DateTime.tryParse(
    '${ref.read(appPreferencesProvider).readJson(_key)?['sent']}',
  );

  Future<void> set(bool enabled) async {
    state = enabled;
    await ref
        .read(appPreferencesProvider)
        .writeJson(_key, enabled ? {'enabled': true} : null);
  }

  Future<void> markSent(DateTime at) => ref
      .read(appPreferencesProvider)
      .writeJson(_key, {'enabled': state, 'sent': at.toIso8601String()});
}

final weekReportProvider = NotifierProvider<WeekReportController, bool>(
  WeekReportController.new,
);
