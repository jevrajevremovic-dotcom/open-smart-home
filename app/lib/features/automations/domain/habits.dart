import 'package:flutter/foundation.dart';

import '../../../integrations/home_assistant/models/ha_history.dart';
import '../../devices/domain/smart_home_device.dart';
import 'simple_automation.dart';

/// What a habit is tied to: a time of day, or something that just
/// happened (a door opened, someone came home).
enum HabitKind { time, after }

/// Something the household keeps doing by hand that an automation could
/// do: found in Home Assistant's logbook, on the device, nothing sent
/// anywhere. The user still reviews it in the editor before it is saved.
@immutable
class HabitSuggestion {
  const HabitSuggestion({
    required this.key,
    required this.kind,
    required this.automation,
    required this.seen,
    required this.outOf,
  });

  /// Stable id, to remember "no thanks".
  final String key;
  final HabitKind kind;

  /// Without a name: the editor makes one.
  final SimpleAutomation automation;

  /// [HabitKind.time]: on how many of [outOf] days. [HabitKind.after]:
  /// how many times, out of [outOf] times the trigger happened.
  final int seen;
  final int outOf;

  AutomationAction get action => automation.actions.single;
  AutomationTrigger get trigger => automation.triggers.single;
  Set<int>? get weekdays =>
      automation.conditions.whereType<WeekdayCondition>().firstOrNull?.weekdays;
}

/// The service that puts [d] into [state], if an automation may call it
/// (unlocking and disarming never).
String? serviceForState(SmartHomeDevice d, String state) {
  if (d.kind.isRoutine) return null;
  final service = switch (state) {
    'on' => 'turn_on',
    'off' => 'turn_off',
    'open' => 'open_cover',
    'closed' => 'close_cover',
    'locked' => 'lock',
    _ => null,
  };
  return service != null && actionServicesFor(d).contains(service)
      ? service
      : null;
}

const _weekdays = {1, 2, 3, 4, 5};
const _weekend = {6, 7};

/// Minutes apart on a 24-hour clock (23:50 and 00:10 are 20 apart).
int _clockDistance(int a, int b) {
  final d = (a - b).abs() % 1440;
  return d > 720 ? 1440 - d : d;
}

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

/// Habits in [entries] (Home Assistant's logbook for the whole home over
/// the last days). Only changes nobody's automation made count; the
/// most regular come first, at most [limit].
List<HabitSuggestion> findHabits(
  List<HaLogbookEntry> entries,
  Map<String, SmartHomeDevice> devices, {
  int limit = 5,
  Duration window = const Duration(minutes: 30),
  Duration followWithin = const Duration(minutes: 3),
}) {
  final sorted = [...entries]..sort((a, b) => a.when.compareTo(b.when));
  // Days the logbook has anything for (HA keeps 10 days by default).
  final observed = {for (final e in sorted) _day(e.when)};
  if (observed.length < 4) return const [];

  final manual = <(String, String, String), List<DateTime>>{};
  for (final e in sorted) {
    final id = e.entityId;
    final state = e.state;
    if (id == null || state == null || e.automated) continue;
    final d = devices[id];
    if (d == null) continue;
    final service = serviceForState(d, state);
    if (service == null) continue;
    (manual[(id, state, service)] ??= []).add(e.when);
  }

  final out = <HabitSuggestion>[
    for (final MapEntry(key: (id, _, service), value: times) in manual.entries)
      ?_timeHabit(id, service, times, observed, window.inMinutes),
    ..._afterHabits(sorted, manual, devices, followWithin),
  ];
  out.sort((a, b) => (b.seen / b.outOf).compareTo(a.seen / a.outOf));
  return out.take(limit).toList();
}

HabitSuggestion? _timeHabit(
  String entityId,
  String service,
  List<DateTime> times,
  Set<DateTime> observed,
  int window,
) {
  final minutes = [for (final t in times) t.hour * 60 + t.minute];
  // The time of day with the most days around it.
  // Days are counted from twelve hours away from the time, so a habit
  // around midnight is one evening, not two half days.
  DateTime dayOf(DateTime t, int c) => _day(t.add(Duration(minutes: 720 - c)));
  int? center;
  var bestDays = 0;
  var bestSpread = 0;
  for (final c in minutes) {
    final days = <DateTime>{};
    var spread = 0;
    for (final (i, m) in minutes.indexed) {
      final d = _clockDistance(m, c);
      if (d <= window && days.add(dayOf(times[i], c))) spread += d;
    }
    if (days.length > bestDays ||
        (days.length == bestDays && spread < bestSpread)) {
      center = c;
      bestDays = days.length;
      bestSpread = spread;
    }
  }
  if (center == null) return null;

  // Per day the change closest to it.
  final byDay = <DateTime, int>{};
  for (final (i, m) in minutes.indexed) {
    if (_clockDistance(m, center) > window) continue;
    final day = dayOf(times[i], center);
    final old = byDay[day];
    if (old == null ||
        _clockDistance(m, center) < _clockDistance(old, center)) {
      byDay[day] = m;
    }
  }
  final weekdaysSeen = {for (final d in byDay.keys) d.weekday};
  final observedWeekdays = {for (final d in observed) d.weekday};
  final Set<int>? only;
  if (weekdaysSeen.every(_weekdays.contains) &&
      observedWeekdays.any(_weekend.contains)) {
    only = _weekdays;
  } else if (weekdaysSeen.every(_weekend.contains) &&
      observedWeekdays.any(_weekdays.contains)) {
    only = _weekend;
  } else {
    only = null;
  }
  final eligible = observed
      .where((d) => only == null || only.contains(d.weekday))
      .length;
  final enough = only == _weekend ? 3 : 4;
  if (byDay.length < enough || byDay.length * 2 < eligible) return null;

  // Average around the center (so 23:55 and 00:05 give midnight),
  // rounded to five minutes.
  final offsets = [
    for (final m in byDay.values)
      ((m - center + 720) % 1440 + 1440) % 1440 - 720,
  ];
  final mean = center + offsets.reduce((a, b) => a + b) / offsets.length;
  final at = ((mean / 5).round() * 5) % 1440;
  return HabitSuggestion(
    key: 'time|$entityId|$service|${at ~/ 60}',
    kind: HabitKind.time,
    automation: SimpleAutomation(
      alias: '',
      triggers: [TimeTrigger(at ~/ 60, at % 60)],
      conditions: [if (only != null) WeekdayCondition(only)],
      actions: [AutomationAction(entityId, service)],
    ),
    seen: byDay.length,
    outOf: eligible,
  );
}

/// Classes of binary sensors that make a good "when" (motion is left out:
/// it fires all day, and HA's own motion lighting blueprint does it better).
const _openings = {'door', 'garage_door', 'window', 'opening'};

/// A trigger worth following: `(entity, state)`, or `null`.
(String, String)? _triggerOf(
  HaLogbookEntry e,
  Map<String, SmartHomeDevice> devices,
) {
  final id = e.entityId;
  if (id == null) return null;
  final d = devices[id];
  return switch ((id.split('.').first, e.state)) {
    ('binary_sensor', 'on')
        when _openings.contains(d?.metadata.haDeviceClass) =>
      (id, 'on'),
    ('person', 'home') => (id, 'home'),
    ('lock', 'unlocked') => (id, 'unlocked'),
    _ => null,
  };
}

List<HabitSuggestion> _afterHabits(
  List<HaLogbookEntry> sorted,
  Map<(String, String, String), List<DateTime>> manual,
  Map<String, SmartHomeDevice> devices,
  Duration within,
) {
  final triggers = <(String, String), List<DateTime>>{};
  for (final e in sorted) {
    if (_triggerOf(e, devices) case final t?) (triggers[t] ??= []).add(e.when);
  }
  if (triggers.isEmpty) return const [];

  final out = <HabitSuggestion>[];
  for (final MapEntry(key: (id, _, service), value: actions)
      in manual.entries) {
    for (final MapEntry(key: (trigger, to), value: fired) in triggers.entries) {
      if (trigger == id) continue;
      final followed = [
        for (final a in actions)
          if (fired.any((f) => !f.isAfter(a) && a.difference(f) <= within)) a,
      ];
      final days = {for (final a in followed) _day(a)};
      // Often enough, and not a trigger that mostly happens without it.
      if (followed.length < 4 ||
          days.length < 3 ||
          followed.length * 10 < fired.length * 3) {
        continue;
      }
      final d = devices[id];
      final daytime = followed.where((t) => t.hour >= 8 && t.hour < 17).length;
      final dark =
          d != null &&
          d.kind.isLight &&
          service == 'turn_on' &&
          daytime * 5 < followed.length;
      out.add(
        HabitSuggestion(
          key: 'after|$trigger|$to|$id|$service',
          kind: HabitKind.after,
          automation: SimpleAutomation(
            alias: '',
            triggers: [DeviceTrigger(trigger, to)],
            conditions: [if (dark) const SunCondition(dark: true)],
            actions: [AutomationAction(id, service)],
          ),
          seen: followed.length,
          outOf: fired.length,
        ),
      );
    }
  }
  return out;
}
