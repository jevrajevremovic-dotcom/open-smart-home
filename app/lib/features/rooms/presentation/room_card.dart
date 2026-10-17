import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../kiosk/application/kiosk_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../../dashboard/application/home_summaries.dart';
import '../../devices/presentation/device_presentation.dart';

/// Maps common Material Design Icons names used for HA areas to Material
/// icons. Unknown names fall back to a generic room icon.
IconData roomIcon(String? mdi) => switch (mdi) {
  'mdi:sofa' ||
  'mdi:sofa-outline' ||
  'mdi:television' => Icons.weekend_outlined,
  'mdi:bed' ||
  'mdi:bed-outline' ||
  'mdi:bed-king' ||
  'mdi:bed-empty' => Icons.bed_outlined,
  'mdi:door' ||
  'mdi:door-open' ||
  'mdi:door-closed' => Icons.door_front_door_outlined,
  'mdi:countertop' ||
  'mdi:stove' ||
  'mdi:fridge' ||
  'mdi:silverware-fork-knife' => Icons.kitchen_outlined,
  'mdi:garage' || 'mdi:garage-variant' => Icons.garage_outlined,
  'mdi:tree' ||
  'mdi:flower' ||
  'mdi:grass' ||
  'mdi:pine-tree' => Icons.park_outlined,
  'mdi:shower' || 'mdi:bathtub' || 'mdi:toilet' => Icons.bathtub_outlined,
  'mdi:desk' || 'mdi:laptop' || 'mdi:briefcase' => Icons.desk_outlined,
  'mdi:baby-carriage' ||
  'mdi:teddy-bear' ||
  'mdi:human-child' => Icons.child_care_outlined,
  'mdi:stairs' => Icons.stairs_outlined,
  'mdi:washing-machine' => Icons.local_laundry_service_outlined,
  _ => Icons.meeting_room_outlined,
};

class RoomCard extends ConsumerWidget {
  const RoomCard({
    super.key,
    required this.roomId,
    required this.name,
    this.icon,
  });

  /// `null` = devices without a room.
  final String? roomId;
  final String name;
  final String? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summary = ref.watch(roomSummaryProvider(roomId));
    final warning = context.statusColors.warning;

    // Bubble style: a room where something is on turns pastel.
    final active = summary.lightsOn > 0 || summary.activeCount > 0;
    final pastel = context.deviceAccents.of(DeviceAccent.light);
    final fg = active ? pastel.onContainer : theme.colorScheme.onSurface;
    final sub = active
        ? pastel.onContainer.withValues(alpha: 0.75)
        : theme.colorScheme.onSurfaceVariant;
    final detail = [
      if (summary.lightsOn > 0) l10n.roomLightsOn(summary.lightsOn),
      if (summary.temperature == null || summary.lightsOn == 0)
        l10n.roomDevicesCount(summary.deviceCount),
    ].join(' · ');

    return Card(
      color: active ? pastel.container : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.room(roomId, kiosk: ref.read(kioskActiveProvider)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(color: fg),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (summary.alertCount > 0)
                    Tooltip(
                      message: l10n.summaryAlerts,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6, top: 8),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: active ? fg : warning,
                        ),
                      ),
                    ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: active
                          ? pastel.onContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      roomIcon(icon),
                      size: 22,
                      color: active
                          ? pastel.container
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (summary.temperature != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatNumber(
                          l10n.localeName,
                          summary.temperature!,
                          unit: '°',
                        ),
                        style: theme.textTheme.headlineMedium?.copyWith(
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
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: sub,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(color: sub),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive grid of room cards (lazy).
class RoomSliverGrid extends ConsumerWidget {
  const RoomSliverGrid({super.key, required this.rooms});

  final List<(String?, String, String?)> rooms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8);
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 150 * textScale,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, i) {
        final (id, name, icon) = rooms[i];
        return RoomCard(key: ValueKey(id), roomId: id, name: name, icon: icon);
      },
    );
  }
}
