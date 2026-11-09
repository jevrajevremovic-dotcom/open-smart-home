import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../integrations/home_assistant/models/ha_models.dart';
import '../../authentication/application/session_controller.dart';

/// The price of electricity for one stretch of time.
@immutable
class PriceSlot {
  const PriceSlot(this.start, this.end, this.price);

  final DateTime start;
  final DateTime end;
  final double price;

  Duration get length => end.difference(start);
}

/// Hourly (or 15-minute) prices published by a Home Assistant sensor.
@immutable
class ElectricityPrices {
  const ElectricityPrices({
    required this.entityId,
    required this.name,
    required this.slots,
    this.unit,
  });

  final String entityId;
  final String name;
  final String? unit;

  /// Oldest first, today and (from the afternoon) tomorrow.
  final List<PriceSlot> slots;

  PriceSlot? at(DateTime t) =>
      slots.where((s) => !t.isBefore(s.start) && t.isBefore(s.end)).firstOrNull;
}

/// List attributes that carry prices, as the popular integrations name
/// them: Nord Pool (HACS) `raw_today`/`raw_tomorrow`, ENTSO-e
/// `prices_today`/`prices_tomorrow`/`prices`, EPEX Spot `data`.
const _listKeys = [
  'raw_today',
  'raw_tomorrow',
  'prices_today',
  'prices_tomorrow',
  'prices',
  'data',
];
const _startKeys = ['start', 'time', 'start_time'];
const _endKeys = ['end', 'end_time'];
const _priceKeys = ['value', 'price', 'price_per_kwh', 'total'];

/// The price slots in [state]'s attributes; empty when it has none.
List<PriceSlot> parsePriceSlots(HaEntityState state) {
  final byStart = <DateTime, (DateTime?, double)>{};
  for (final key in _listKeys) {
    final list = state.attributes[key];
    if (list is! List) continue;
    for (final item in list) {
      if (item is! Map) continue;
      final start = _time(_first(item, _startKeys));
      final price = _number(_first(item, _priceKeys));
      if (start == null || price == null) continue;
      byStart[start] = (_time(_first(item, _endKeys)), price);
    }
  }
  final starts = byStart.keys.toList()..sort();
  return [
    for (final (i, start) in starts.indexed)
      PriceSlot(
        start,
        byStart[start]!.$1 ??
            (i + 1 < starts.length
                ? starts[i + 1]
                : start.add(const Duration(hours: 1))),
        byStart[start]!.$2,
      ),
  ];
}

Object? _first(Map<Object?, Object?> m, List<String> keys) {
  for (final k in keys) {
    if (m[k] != null) return m[k];
  }
  return null;
}

DateTime? _time(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

double? _number(Object? v) => switch (v) {
  num() => v.toDouble(),
  String() => double.tryParse(v),
  _ => null,
};

/// The cheapest time to run something for [length], starting no earlier
/// than the slot [now] is in: `(start, end, average price)`, or `null`
/// when the known prices do not reach that far.
(DateTime, DateTime, double)? cheapestWindow(
  List<PriceSlot> slots,
  Duration length,
  DateTime now,
) {
  final future = slots.where((s) => s.end.isAfter(now)).toList();
  (DateTime, DateTime, double)? best;
  for (var i = 0; i < future.length; i++) {
    var covered = Duration.zero;
    var cost = 0.0;
    var j = i;
    while (j < future.length && covered < length) {
      // Only back-to-back slots make one window.
      if (j > i && future[j].start != future[j - 1].end) break;
      final take = length - covered < future[j].length
          ? length - covered
          : future[j].length;
      cost += future[j].price * take.inSeconds;
      covered += take;
      j++;
    }
    if (covered < length) continue;
    final average = cost / length.inSeconds;
    if (best == null || average < best.$3) {
      final start = future[i].start;
      best = (start, start.add(length), average);
    }
  }
  return best;
}

/// The first sensor with a price list, read once per opening.
final electricityPricesProvider =
    FutureProvider.autoDispose<ElectricityPrices?>((ref) async {
      final api = ref.watch(homeAssistantApiProvider);
      if (api == null) return null;
      for (final s in await api.fetchStates()) {
        if (!s.entityId.startsWith('sensor.')) continue;
        final slots = parsePriceSlots(s);
        if (slots.length < 4) continue;
        final name = s.attributes['friendly_name'];
        final unit = s.attributes['unit_of_measurement'];
        return ElectricityPrices(
          entityId: s.entityId,
          name: name is String ? name : s.entityId,
          unit: unit is String ? unit : null,
          slots: slots,
        );
      }
      return null;
    });
