import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/responsive.dart';
import '../application/device_providers.dart';
import '../application/zigbee_map.dart';

Future<void> showZigbeeMap(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ZigbeeMapScreen()));

/// Who talks to whom in the Zigbee network, and how well: the coordinator
/// in the middle, routers around it, battery devices outside. Weak links
/// are red and listed below, with what usually helps.
class ZigbeeMapScreen extends ConsumerStatefulWidget {
  const ZigbeeMapScreen({super.key});

  @override
  ConsumerState<ZigbeeMapScreen> createState() => _ZigbeeMapScreenState();
}

class _ZigbeeMapScreenState extends ConsumerState<ZigbeeMapScreen> {
  String? _selected;

  static const _mapSize = Size(720, 720);

  String _name(ZigbeeNetwork net, String ieee) => net.node(ieee)?.name ?? ieee;

  /// The Home Assistant device's main entity, to open it.
  String? _entityFor(ZigbeeNode node) {
    final id = node.haDeviceId;
    if (id == null) return null;
    final devices = ref.read(homeSnapshotProvider).devices.values;
    return devices
            .where((d) => d.deviceId == id && !d.isAuxiliary)
            .firstOrNull
            ?.id ??
        devices.where((d) => d.deviceId == id).firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final network = ref.watch(zigbeeNetworkProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.zigbeeMapTitle),
        actions: [
          IconButton(
            tooltip: l10n.checkAgain,
            onPressed: network.isLoading
                ? null
                : () => ref.invalidate(zigbeeNetworkProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: network.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.zigbeeMapLoading, textAlign: TextAlign.center),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e is AppFailure && e.kind == FailureKind.authorization
                  ? l10n.presenceNeedsAdmin
                  : l10n.zigbeeMapFailed,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (net) {
          if (net == null || net.nodes.isEmpty) {
            return Center(child: Text(l10n.zigbeeMapNone));
          }
          final positions = layoutZigbee(net, _mapSize);
          final selected = _selected == null ? null : net.node(_selected!);
          final weak = net.weakLinks;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ConstrainedContent(
                maxWidth: 760,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.zigbeeMapSummary(
                        net.nodes
                            .where((n) => n.role == ZigbeeRole.router)
                            .length,
                        net.nodes.where((n) => n.role == ZigbeeRole.end).length,
                        weak.length,
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    _Legend(),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: 1,
                      child: Card.outlined(
                        clipBehavior: Clip.antiAlias,
                        child: InteractiveViewer(
                          maxScale: 4,
                          minScale: 0.5,
                          boundaryMargin: const EdgeInsets.all(200),
                          child: FittedBox(
                            child: GestureDetector(
                              key: const Key('zigbeeMap'),
                              onTapUp: (d) {
                                String? hit;
                                var best = 30.0;
                                for (final MapEntry(:key, :value)
                                    in positions.entries) {
                                  final dist =
                                      (value - d.localPosition).distance;
                                  if (dist < best) {
                                    best = dist;
                                    hit = key;
                                  }
                                }
                                setState(() => _selected = hit);
                              },
                              child: Semantics(
                                label: l10n.zigbeeMapTitle,
                                child: CustomPaint(
                                  size: _mapSize,
                                  painter: _MapPainter(
                                    net: net,
                                    positions: positions,
                                    selected: _selected,
                                    theme: theme,
                                    status: context.statusColors,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (selected != null) ...[
                      const SizedBox(height: 12),
                      _NodeCard(
                        node: selected,
                        net: net,
                        name: (id) => _name(net, id),
                        entityId: _entityFor(selected),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      l10n.zigbeeWeakTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weak.isEmpty ? l10n.zigbeeWeakNone : l10n.zigbeeWeakHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    for (final l in weak)
                      ListTile(
                        key: ValueKey('zigbeeWeak-${l.a}-${l.b}'),
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.signal_cellular_alt_1_bar,
                          color: context.statusColors.critical,
                        ),
                        title: Text('${_name(net, l.a)} ↔ ${_name(net, l.b)}'),
                        trailing: Text('LQI ${l.lqi}'),
                        onTap: () => setState(
                          () => _selected =
                              net.node(l.a)?.role == ZigbeeRole.end ? l.a : l.b,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final status = context.statusColors;
    Widget dot(Color c, String label, {double size = 12}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
    Widget line(Color c, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 18, height: 3, color: c),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        dot(theme.colorScheme.primary, l10n.zigbeeCoordinator, size: 14),
        dot(theme.colorScheme.tertiary, l10n.zigbeeRouter),
        dot(theme.colorScheme.outline, l10n.zigbeeEndDevice, size: 10),
        line(status.ok, l10n.zigbeeLinkGood),
        line(theme.colorScheme.outlineVariant, l10n.zigbeeLinkOk),
        line(status.critical, l10n.zigbeeLinkWeak),
      ],
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.node,
    required this.net,
    required this.name,
    required this.entityId,
  });

  final ZigbeeNode node;
  final ZigbeeNetwork net;
  final String Function(String ieee) name;
  final String? entityId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final links = net.links.where((l) => l.touches(node.ieee)).toList()
      ..sort((a, b) => (b.lqi ?? 0).compareTo(a.lqi ?? 0));
    return Card.filled(
      key: const Key('zigbeeNode'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(node.name, style: theme.textTheme.titleMedium),
            Text(
              [
                switch (node.role) {
                  ZigbeeRole.coordinator => l10n.zigbeeCoordinator,
                  ZigbeeRole.router => l10n.zigbeeRouter,
                  ZigbeeRole.end => l10n.zigbeeEndDevice,
                },
                if (!node.available) l10n.zigbeeUnavailable,
                node.ieee,
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final l in links)
              Text(
                '↔ ${name(l.other(node.ieee))}: LQI ${l.lqi ?? '?'}',
                style: theme.textTheme.bodyMedium,
              ),
            if (entityId != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.device(entityId!)),
                  child: Text(l10n.zigbeeOpenDevice),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.net,
    required this.positions,
    required this.selected,
    required this.theme,
    required this.status,
  });

  final ZigbeeNetwork net;
  final Map<String, Offset> positions;
  final String? selected;
  final ThemeData theme;
  final StatusColors status;

  @override
  void paint(Canvas canvas, Size size) {
    final scheme = theme.colorScheme;
    final line = Paint()..strokeCap = StrokeCap.round;
    for (final l in net.links) {
      final a = positions[l.a];
      final b = positions[l.b];
      if (a == null || b == null) continue;
      final lqi = l.lqi;
      final focus = selected == null || l.touches(selected!);
      line
        ..strokeWidth = focus && selected != null ? 3 : 2
        ..color =
            (lqi == null
                    ? scheme.outlineVariant
                    : lqi < weakLqi
                    ? status.critical
                    : lqi >= goodLqi
                    ? status.ok
                    : scheme.outlineVariant)
                .withValues(alpha: focus ? 1 : 0.2);
      canvas.drawLine(a, b, line);
      if (lqi != null && lqi < weakLqi && focus) {
        _label(canvas, '$lqi', (a + b) / 2, status.critical, bold: true);
      }
    }
    final fill = Paint();
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = scheme.onSurface;
    for (final n in net.nodes) {
      final p = positions[n.ieee];
      if (p == null) continue;
      final (r, color) = switch (n.role) {
        ZigbeeRole.coordinator => (16.0, scheme.primary),
        ZigbeeRole.router => (11.0, scheme.tertiary),
        ZigbeeRole.end => (8.0, scheme.outline),
      };
      // A 2px surface ring keeps nodes apart from the lines.
      fill.color = scheme.surface;
      canvas.drawCircle(p, r + 2, fill);
      fill.color = n.available ? color : color.withValues(alpha: 0.35);
      canvas.drawCircle(p, r, fill);
      if (n.ieee == selected) canvas.drawCircle(p, r + 4, ring);
      final short = n.name.length > 16 ? '${n.name.substring(0, 15)}…' : n.name;
      _label(canvas, short, p + Offset(0, r + 10), scheme.onSurface);
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at,
    Color color, {
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: bold ? FontWeight.w700 : null,
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.net != net || old.selected != selected || old.theme != theme;
}
