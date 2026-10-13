import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/value_list.dart';
import '../../authentication/application/session_controller.dart';
import '../data/home_state_repository.dart';
import '../domain/device_kind.dart';
import '../domain/smart_home_device.dart';

/// Lives as long as the session's WebSocket manager.
final homeStateRepositoryProvider = Provider<HomeStateRepository?>((ref) {
  final manager = ref.watch(webSocketManagerProvider);
  if (manager == null) return null;
  final repository = HomeStateRepository(manager)..start();
  ref.onDispose(() => unawaited(repository.dispose()));
  return repository;
});

class HomeSnapshotController extends Notifier<HomeSnapshot> {
  @override
  HomeSnapshot build() {
    final repository = ref.watch(homeStateRepositoryProvider);
    if (repository == null) return HomeSnapshot.empty;
    final subscription = repository.snapshots.listen((s) => state = s);
    ref.onDispose(() => unawaited(subscription.cancel()));
    return repository.current;
  }
}

final homeSnapshotProvider =
    NotifierProvider<HomeSnapshotController, HomeSnapshot>(
      HomeSnapshotController.new,
    );

/// One device. Widgets watching it rebuild only when *this* device changes,
/// because the repository keeps unchanged devices identical.
final deviceProvider = Provider.family<SmartHomeDevice?, String>(
  (ref, id) => ref.watch(homeSnapshotProvider.select((s) => s.devices[id])),
);

final syncStatusProvider = Provider<SyncStatus>(
  (ref) => ref.watch(homeSnapshotProvider.select((s) => s.status)),
);

/// Devices meant for normal lists: no auxiliary entities, no routines.
final visibleDeviceIdsProvider = Provider<ValueList<String>>((ref) {
  final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
  final visible =
      devices.values
          .where(
            (d) =>
                !d.isAuxiliary &&
                !d.kind.isRoutine &&
                d.kind != DeviceKind.unknown,
          )
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return ValueList([for (final d in visible) d.id]);
});

/// Rooms sorted by name.
final roomsProvider = Provider<ValueList<Room>>((ref) {
  final rooms =
      ref.watch(homeSnapshotProvider.select((s) => s.rooms)).values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return ValueList(rooms);
});

/// Visible device ids per room id; devices without a room use `null`.
final deviceIdsByRoomProvider = Provider<Map<String?, ValueList<String>>>((
  ref,
) {
  final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
  final result = <String?, List<String>>{};
  for (final id in ref.watch(visibleDeviceIdsProvider)) {
    result.putIfAbsent(devices[id]?.roomId, () => []).add(id);
  }
  return {for (final e in result.entries) e.key: ValueList(e.value)};
});
