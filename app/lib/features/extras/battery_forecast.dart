import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/application/session_controller.dart';
import 'batteries.dart';

/// A battery counts as empty here: most devices stop working around it.
const batteryEmptyPercent = 5;

/// Days until a battery reaches [batteryEmptyPercent], from daily averages
/// ([points], oldest first): a straight line through the days since the
/// battery was last replaced. `null` when it is not clearly going down or
/// there is too little to tell (under a week, or under 3 points dropped).
/// Counted from [current] (the level now) when given.
double? batteryDaysLeft(List<(DateTime, double)> points, {double? current}) {
  if (points.length < 2) return null;
  // Start after the last jump up: a new battery.
  var from = 0;
  for (var i = 1; i < points.length; i++) {
    if (points[i].$2 - points[i - 1].$2 >= 15) from = i;
  }
  final p = points.sublist(from);
  if (p.length < 2) return null;
  final t0 = p.first.$1;
  final xs = [for (final (t, _) in p) t.difference(t0).inHours / 24];
  final ys = [for (final (_, v) in p) v];
  if (xs.last < 7 || ys.first - ys.last < 3) return null;
  final n = p.length;
  final mx = xs.reduce((a, b) => a + b) / n;
  final my = ys.reduce((a, b) => a + b) / n;
  var sxy = 0.0;
  var sxx = 0.0;
  for (var i = 0; i < n; i++) {
    sxy += (xs[i] - mx) * (ys[i] - my);
    sxx += (xs[i] - mx) * (xs[i] - mx);
  }
  if (sxx == 0) return null;
  final slope = sxy / sxx; // percent per day
  if (slope > -0.05) return null;
  final left = ((current ?? ys.last) - batteryEmptyPercent) / -slope;
  return left < 0 ? 0 : left;
}

/// Daily means of `recorder/statistics_during_period` (`types: [mean]`).
Map<String, List<(DateTime, double)>> parseMeans(Object? json) => {
  if (json is Map)
    for (final MapEntry(:key, :value) in json.entries)
      if (key is String && value is List)
        key: [
          for (final row in value)
            if (row is Map && row['mean'] is num)
              if (switch (row['start']) {
                    final num ms => DateTime.fromMillisecondsSinceEpoch(
                      ms.toInt(),
                    ),
                    final String s => DateTime.tryParse(s),
                    _ => null,
                  }
                  case final start?)
                (start, (row['mean']! as num).toDouble()),
        ]..sort((a, b) => a.$1.compareTo(b.$1)),
};

/// Days left per battery sensor, from Home Assistant's long-term
/// statistics (kept beyond the 10 days of history) of the last 90 days.
final batteryForecastProvider = FutureProvider.autoDispose<Map<String, double>>(
  (ref) async {
    final ws = ref.watch(webSocketManagerProvider);
    final levels = {
      for (final b in ref.watch(batteriesProvider))
        if (b.sensorId != null) b.sensorId!: b.percent?.toDouble(),
    };
    final ids = levels.keys.toList();
    if (ws == null || ids.isEmpty) return const {};
    final now = DateTime.now();
    final result = await ws.sendCommand({
      'type': 'recorder/statistics_during_period',
      'start_time': now
          .subtract(const Duration(days: 90))
          .toUtc()
          .toIso8601String(),
      'end_time': now.toUtc().toIso8601String(),
      'statistic_ids': ids,
      'period': 'day',
      'types': ['mean'],
    });
    return {
      for (final MapEntry(:key, :value) in parseMeans(result).entries)
        key: ?batteryDaysLeft(value, current: levels[key]),
    };
  },
);
