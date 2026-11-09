import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../integrations/home_assistant/models/ha_history.dart';
import '../../authentication/application/session_controller.dart';
import '../domain/device_kind.dart';
import '../domain/smart_home_device.dart';
import 'device_providers.dart';

/// What may be wrong with a device.
enum HealthIssue { offline, flaky, weakSignal, lowBattery }

/// Looking back this far for outages.
const healthSpan = Duration(days: 7);

/// Outages in [healthSpan] from which a device counts as unreliable.
const flakyOutages = 3;

@immutable
class DeviceHealth {
  const DeviceHealth({
    required this.issues,
    this.outages = 0,
    this.offlineSince,
    this.lastOutage,
    this.downtime = Duration.zero,
  });

  final List<HealthIssue> issues;

  /// Times it became unavailable in [healthSpan].
  final int outages;

  /// When the current outage started (if it is offline now and the
  /// history shows it).
  final DateTime? offlineSince;
  final DateTime? lastOutage;

  /// Total time unavailable in [healthSpan].
  final Duration downtime;

  bool get ok => issues.isEmpty;
}

/// Too weak to rely on: Wi-Fi/BLE RSSI below −80 dBm, Zigbee link
/// quality below 50 of 255, or under 30 % where it is a percentage.
bool weakSignal(double? value, String? unit) {
  if (value == null) return false;
  return switch (unit?.toLowerCase()) {
    'dbm' || 'db' => value < -80,
    'lqi' => value < 50,
    '%' => value < 30,
    _ => false,
  };
}

/// Diagnosis from what HA reports now plus [history] of the main entity
/// over [healthSpan] (oldest first). Nothing is guessed: no history, no
/// outage counts.
DeviceHealth diagnose(
  SmartHomeDevice device,
  List<HaHistoryPoint> history,
  DateTime now,
) {
  var outages = 0;
  DateTime? lastOutage;
  DateTime? down;
  var downtime = Duration.zero;
  String? previous;
  for (final p in history) {
    final off = p.state == 'unavailable';
    if (off && previous != null && previous != 'unavailable') {
      outages++;
      lastOutage = p.at;
    }
    if (off && down == null) down = p.at;
    if (!off && down != null) {
      downtime += p.at.difference(down);
      down = null;
    }
    previous = p.state;
  }
  if (down != null) downtime += now.difference(down);
  final m = device.metadata;
  return DeviceHealth(
    issues: [
      if (!device.available) HealthIssue.offline,
      if (outages >= flakyOutages) HealthIssue.flaky,
      if (weakSignal(m.signalStrength, m.signalUnit)) HealthIssue.weakSignal,
      if (m.batteryLow == true || (m.batteryPercent ?? 100) <= 15)
        HealthIssue.lowBattery,
    ],
    outages: outages,
    offlineSince: device.available ? null : down,
    lastOutage: lastOutage,
    downtime: downtime,
  );
}

/// The diagnosis of one device, with a week of its history.
final deviceHealthProvider = FutureProvider.autoDispose
    .family<DeviceHealth, String>((ref, id) async {
      final device = ref.watch(deviceProvider(id));
      if (device == null) return const DeviceHealth(issues: []);
      final api = ref.watch(homeAssistantApiProvider);
      final now = DateTime.now();
      var history = const <HaHistoryPoint>[];
      if (api != null) {
        try {
          history = await api.fetchHistory(
            device.sourceId,
            now.subtract(healthSpan),
            now,
          );
        } on Object {
          // Without history: only what HA says now.
        }
      }
      return diagnose(device, history, now);
    });

/// Devices to look at across the home (one per physical device): offline
/// or with a weak signal, offline first.
final unhealthyDevicesProvider = Provider<List<SmartHomeDevice>>((ref) {
  final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
  final seen = <String>{};
  final out = <SmartHomeDevice>[];
  // Offline first, then by name.
  final sorted = devices.values.where((d) => !d.isAuxiliary).toList()
    ..sort((a, b) {
      final byState = (a.available ? 1 : 0).compareTo(b.available ? 1 : 0);
      if (byState != 0) return byState;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  for (final d in sorted) {
    if (d.protocol == DeviceProtocol.virtual) continue;
    final bad =
        !d.available ||
        weakSignal(d.metadata.signalStrength, d.metadata.signalUnit);
    if (!bad) continue;
    if (!seen.add(d.deviceId ?? d.id)) continue;
    out.add(d);
  }
  return out;
});
