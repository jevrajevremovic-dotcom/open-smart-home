part of 'kiosk_bubble.dart';

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
