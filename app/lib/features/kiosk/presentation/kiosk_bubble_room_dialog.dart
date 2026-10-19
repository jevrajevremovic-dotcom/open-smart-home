part of 'kiosk_bubble.dart';

/// A room's devices in a window over the kiosk: climate first, lights as
/// coloured cards with the brightness slider inside, then the rest.
Future<void> showBubbleRoom(
  BuildContext context, {
  required String roomId,
  required String name,
}) => showDialog<void>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: 0.6),
  builder: (_) => _BubbleRoomDialog(roomId: roomId, name: name),
);

class _BubbleRoomDialog extends ConsumerWidget {
  const _BubbleRoomDialog({required this.roomId, required this.name});

  final String roomId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final ids =
        ref.watch(deviceIdsByRoomProvider)[roomId]?.toList() ?? const [];
    final devices = [for (final id in ids) ?ref.watch(deviceProvider(id))]
        .where((d) => !d.isAuxiliary)
        .toList();
    final climate = [
      for (final d in devices)
        if (d.kind == DeviceKind.climate || d.kind == DeviceKind.thermostat) d,
    ];
    final lights = [
      for (final d in devices)
        if (d.kind.isLight) d,
    ];
    final other = [
      for (final d in devices)
        if (!climate.contains(d) && !lights.contains(d) && !d.kind.isSensor) d,
    ];
    Widget section(String title, List<Widget> cards) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: GlassColors.text,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= 520 ? 2 : 1;
            final w = (c.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final card in cards) SizedBox(width: w, child: card),
              ],
            );
          },
        ),
      ],
    );
    return Dialog(
      key: const Key('kioskRoomSheet'),
      backgroundColor: BubbleColors.background,
      insetPadding: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: GlassColors.text,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('kioskRoomOpenFull'),
                  tooltip: l10n.allDevices,
                  color: GlassColors.muted,
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.room(roomId, kiosk: true));
                  },
                  icon: const Icon(Icons.open_in_full),
                ),
                IconButton(
                  key: const Key('kioskRoomClose'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  color: GlassColors.text,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (climate.isNotEmpty)
              section(l10n.groupClimate, [
                for (final d in climate)
                  _ClimateBubble(device: d, roomName: name),
              ]),
            if (lights.isNotEmpty)
              section(l10n.groupLights, [
                for (final d in lights)
                  BubbleLightCard(device: d, roomName: name),
              ]),
            if (other.isNotEmpty)
              section(l10n.groupOther, [
                for (final d in other) _DeviceBubble(device: d, roomName: name),
              ]),
          ],
        ),
      ),
    );
  }
}

/// A light as a coloured card: brightness in big type, a round on/off
/// button, and the brightness slider across the bottom of the card.
class BubbleLightCard extends ConsumerStatefulWidget {
  const BubbleLightCard({super.key, required this.device, this.roomName});

  final SmartHomeDevice device;

  /// Left out in front of the device name.
  final String? roomName;

  @override
  ConsumerState<BubbleLightCard> createState() => _BubbleLightCardState();
}

class _BubbleLightCardState extends ConsumerState<BubbleLightCard> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final d = ref.watch(deviceProvider(widget.device.id)) ?? widget.device;
    final on = d.state.isOn == true;
    final dimmable = d.supports(Capability.brightness);
    final percent = _dragging?.round() ?? d.state.brightnessPercent;
    final pastel = DeviceAccents.light.of(DeviceAccent.light);
    final bg = on ? pastel.container : BubbleColors.card;
    final fg = on ? pastel.onContainer : GlassColors.text;
    return Material(
      key: ValueKey('bubbleLight-${d.id}'),
      color: bg,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: d.available
            ? () => runDeviceCommand(context, ref, d, const Toggle())
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          on && dimmable && percent != null
                              ? '$percent %'
                              : (on ? l10n.stateOn : l10n.stateOff),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DevicePresentation.shortName(d.name, widget.roomName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: on ? pastel.onContainer : Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      on ? Icons.lightbulb : Icons.lightbulb_outline,
                      color: on ? pastel.container : Colors.white,
                    ),
                  ),
                ],
              ),
              if (dimmable)
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 14,
                    activeTrackColor: on
                        ? pastel.onContainer.withValues(alpha: 0.85)
                        : GlassColors.faint,
                    inactiveTrackColor: on
                        ? Colors.white.withValues(alpha: 0.7)
                        : BubbleColors.raised,
                    thumbColor: on ? pastel.onContainer : Colors.white,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    key: ValueKey('bubbleLightSlider-${d.id}'),
                    value: (percent ?? 0).toDouble().clamp(0, 100),
                    max: 100,
                    label: '${percent ?? 0} %',
                    onChanged: d.available
                        ? (v) => setState(() => _dragging = v)
                        : null,
                    onChangeEnd: (v) async {
                      final value = v.round().clamp(1, 100);
                      await runDeviceCommand(
                        context,
                        ref,
                        d,
                        SetBrightness(value),
                      );
                      if (mounted) setState(() => _dragging = null);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClimateBubble extends ConsumerWidget {
  const _ClimateBubble({required this.device, this.roomName});

  final SmartHomeDevice device;
  final String? roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final d = ref.watch(deviceProvider(device.id)) ?? device;
    final target = d.state.targetTemperature;
    final step = d.limits.temperatureStep ?? 0.5;
    final current = d.state.currentTemperature;
    Widget button(String key, IconData icon, double delta) => IconButton.filled(
      key: ValueKey('$key-${d.id}'),
      style: IconButton.styleFrom(
        backgroundColor: BubbleColors.raised,
        foregroundColor: GlassColors.text,
      ),
      onPressed: target == null || !d.available
          ? null
          : () => runDeviceCommand(
              context,
              ref,
              d,
              SetTargetTemperature(target + delta),
            ),
      icon: Icon(icon),
    );
    return Material(
      color: BubbleColors.card,
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
        child: Row(
          children: [
            Icon(
              DevicePresentation.icon(d),
              color: DeviceAccents.light.of(DeviceAccent.heat).container,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DevicePresentation.shortName(d.name, roomName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: GlassColors.text,
                    ),
                  ),
                  Text(
                    [
                      DevicePresentation.status(l10n, d),
                      if (current != null)
                        formatNumber(l10n.localeName, current, unit: '°'),
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: GlassColors.faint,
                    ),
                  ),
                ],
              ),
            ),
            button('bubbleClimateDown', Icons.remove, -step),
            SizedBox(
              width: 64,
              child: Text(
                target == null
                    ? '—'
                    : formatNumber(l10n.localeName, target, unit: '°'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: GlassColors.text,
                ),
              ),
            ),
            button('bubbleClimateUp', Icons.add, step),
          ],
        ),
      ),
    );
  }
}

class _DeviceBubble extends ConsumerWidget {
  const _DeviceBubble({required this.device, this.roomName});

  final SmartHomeDevice device;
  final String? roomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final d = ref.watch(deviceProvider(device.id)) ?? device;
    final active = d.state.isOn == true || d.state.isActive == true;
    final accent = DeviceAccents.light.of(DevicePresentation.accent(d));
    final bg = active ? accent.container : BubbleColors.card;
    final fg = active ? accent.onContainer : GlassColors.text;
    final command = clapCommandFor(d);
    return Material(
      key: ValueKey('bubbleDevice-${d.id}'),
      color: bg,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: command == null || !d.available
            ? () => context.push(AppRoutes.device(d.id, kiosk: true))
            : () => runDeviceCommand(context, ref, d, command),
        onLongPress: () => context.push(AppRoutes.device(d.id, kiosk: true)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: active ? accent.onContainer : Colors.black,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  DevicePresentation.icon(d),
                  color: active ? accent.container : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DevicePresentation.shortName(d.name, roomName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(color: fg),
                    ),
                    Text(
                      DevicePresentation.status(l10n, d),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
