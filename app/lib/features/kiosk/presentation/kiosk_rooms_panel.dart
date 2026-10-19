part of 'kiosk_panels.dart';

/// Rooms with lights on and temperature; tap opens the room.
class KioskRoomsPanel extends ConsumerWidget {
  const KioskRoomsPanel({super.key, this.scrollable = true});

  /// `false` inside an already scrolling page (portrait layout).
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomsProvider);
    final l10n = context.l10n;
    final rows = [
      for (var i = 0; i < rooms.length; i++) ...[
        if (i > 0) const Divider(color: GlassColors.border, height: 1),
        _RoomRow(
          roomId: rooms[i].id,
          name: rooms[i].name,
          icon: rooms[i].icon,
          colorIndex: i,
        ),
      ],
    ];
    return GlassPanel(
      key: const Key('kioskRooms'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: scrollable ? MainAxisSize.max : MainAxisSize.min,
        children: [
          GlassTitle(l10n.navRooms),
          if (scrollable)
            Expanded(
              child: EdgeFade(
                child: ListView(padding: EdgeInsets.zero, children: rows),
              ),
            )
          else
            ...rows,
        ],
      ),
    );
  }
}

/// Room icons cycle through the device accent colours so the list is easy
/// to scan; the colour carries no meaning (the name does).
const _roomColors = [
  Color(0xFF3D7BFF),
  Color(0xFFB065E8),
  Color(0xFF2DBE6C),
  Color(0xFFFF5A5F),
  Color(0xFFFFA62B),
  Color(0xFF1FB5C9),
];

class _RoomRow extends ConsumerWidget {
  const _RoomRow({
    required this.roomId,
    required this.name,
    required this.icon,
    required this.colorIndex,
  });

  final String roomId;
  final String name;
  final String? icon;
  final int colorIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summary = ref.watch(roomSummaryProvider(roomId));
    final amber = context.deviceAccents.of(DeviceAccent.light);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(AppRoutes.room(roomId, kiosk: true)),
      child: LayoutBuilder(
        builder: (context, c) {
          // Narrow panel (next to the calendar): only the lights pill.
          final compact = c.maxWidth < 300;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _roomColors[colorIndex % _roomColors.length],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(roomIcon(icon), color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: GlassColors.text,
                    ),
                  ),
                ),
                if (summary.lightsOn > 0)
                  _Pill(
                    color: amber.container,
                    foreground: amber.onContainer,
                    icon: Icons.lightbulb,
                    text: '${summary.lightsOn}',
                    semantics: l10n.roomLightsOn(summary.lightsOn),
                  ),
                if (summary.temperature != null && !compact) ...[
                  const SizedBox(width: 6),
                  _Pill(
                    color: GlassColors.fill,
                    foreground: GlassColors.text,
                    text: formatNumber(
                      l10n.localeName,
                      summary.temperature!,
                      unit: '°',
                    ),
                  ),
                ],
                if (summary.alertCount > 0) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.warning_amber_rounded,
                    color: context.statusColors.warning,
                    semanticLabel: l10n.summaryAlerts,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.color,
    required this.foreground,
    required this.text,
    this.icon,
    this.semantics,
  });

  final Color color;
  final Color foreground;
  final String text;
  final IconData? icon;
  final String? semantics;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semantics,
    excludeSemantics: semantics != null,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: foreground),
          ),
        ],
      ),
    ),
  );
}
