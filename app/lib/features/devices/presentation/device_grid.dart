import 'package:flutter/material.dart';

import '../../../core/widgets/responsive.dart';
import 'device_tile.dart';

/// Lazily built, responsive grid of [DeviceTile]s.
///
/// Tile width adapts to the screen (wider on tablets and wall panels); tile
/// height grows with the user's text scale so labels never get clipped.
class DeviceSliverGrid extends StatelessWidget {
  const DeviceSliverGrid({
    super.key,
    required this.deviceIds,
    this.withoutRoomName = false,
  });

  final List<String> deviceIds;

  /// See [DeviceTile.withoutRoomName].
  final bool withoutRoomName;

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8);
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: switch (size) {
          WindowSize.compact => 200,
          WindowSize.medium => 220,
          _ => 240,
        },
        mainAxisExtent: 148 * textScale,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: deviceIds.length,
      itemBuilder: (context, i) => DeviceTile(
        key: ValueKey(deviceIds[i]),
        deviceId: deviceIds[i],
        withoutRoomName: withoutRoomName,
      ),
    );
  }
}

/// Section title used on dashboard, rooms and favorites screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Centered hint for empty sections.
class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}
