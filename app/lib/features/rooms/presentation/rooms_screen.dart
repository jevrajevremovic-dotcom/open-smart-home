import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../dashboard/application/home_summaries.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/presentation/device_grid.dart';
import '../../devices/presentation/stale_data_banner.dart';
import 'room_card.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rooms = ref.watch(roomsProvider);
    final hasUnassigned = ref.watch(
      deviceIdsByRoomProvider.select((m) => m.containsKey(null)),
    );

    final entries = [
      for (final r in rooms) (r.id, r.name, r.icon),
      if (hasUnassigned) (null, l10n.roomNoRoom, null),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navRooms),
        actions: [
          IconButton(
            key: const Key('openAddDevice'),
            tooltip: l10n.addDeviceTitle,
            onPressed: () => context.push(AppRoutes.addDevice),
            icon: const Icon(Icons.add),
          ),
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.allDevices),
            icon: const Icon(Icons.list),
            label: Text(l10n.allDevices),
          ),
        ],
      ),
      body: MockModeBanner(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: entries.isEmpty
                  ? SliverToBoxAdapter(
                      child: EmptyHint(
                        icon: Icons.meeting_room_outlined,
                        text: l10n.noRoomsYet,
                      ),
                    )
                  : RoomSliverGrid(rooms: entries),
            ),
          ],
        ),
      ),
    );
  }
}

/// Devices of one room, grouped by category. `roomId == null` shows
/// devices without a room.
class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({super.key, required this.roomId});

  final String? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final name = roomId == null
        ? l10n.roomNoRoom
        : ref.watch(
                homeSnapshotProvider.select((s) => s.rooms[roomId]?.name),
              ) ??
              '';
    final groups = ref.watch(roomDeviceGroupsProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: CustomScrollView(
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: StaleDataBanner()),
          ),
          if (groups.isEmpty)
            SliverToBoxAdapter(
              child: EmptyHint(
                icon: Icons.devices_other_outlined,
                text: l10n.roomEmpty,
              ),
            ),
          for (final (group, ids) in groups) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(groupLabel(l10n, group)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: DeviceSliverGrid(deviceIds: ids),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

/// Every visible device, alphabetically.
class AllDevicesScreen extends ConsumerWidget {
  const AllDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(visibleDeviceIdsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.allDevices)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: DeviceSliverGrid(deviceIds: ids),
          ),
        ],
      ),
    );
  }
}

String groupLabel(AppLocalizations l10n, DeviceGroup group) => switch (group) {
  DeviceGroup.lights => l10n.groupLights,
  DeviceGroup.climate => l10n.groupClimate,
  DeviceGroup.covers => l10n.groupCovers,
  DeviceGroup.switches => l10n.groupSwitches,
  DeviceGroup.security => l10n.groupSecurity,
  DeviceGroup.sensors => l10n.groupSensors,
  DeviceGroup.media => l10n.groupMedia,
  DeviceGroup.energy => l10n.groupEnergy,
  DeviceGroup.other => l10n.groupOther,
};
