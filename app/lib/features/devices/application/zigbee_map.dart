import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../add_device/application/add_device_providers.dart';
import '../../add_device/data/zigbee_pairing.dart';
import '../../authentication/application/session_controller.dart';

/// Coordinator (the USB stick), router (mains-powered: plugs, bulbs) or
/// end device (battery sensors), as Zigbee calls them.
enum ZigbeeRole { coordinator, router, end }

@immutable
class ZigbeeNode {
  const ZigbeeNode({
    required this.ieee,
    required this.name,
    required this.role,
    this.haDeviceId,
    this.available = true,
  });

  final String ieee;
  final String name;
  final ZigbeeRole role;

  /// Home Assistant's device registry id, to open the device.
  final String? haDeviceId;
  final bool available;
}

/// A radio link between two devices with its quality (LQI, 0–255).
@immutable
class ZigbeeLink {
  const ZigbeeLink(this.a, this.b, this.lqi);

  final String a;
  final String b;
  final int? lqi;

  bool touches(String ieee) => a == ieee || b == ieee;
  String other(String ieee) => a == ieee ? b : a;
}

/// Below this a link is weak (messages get lost).
const weakLqi = 80;

/// At least this is a good link.
const goodLqi = 150;

@immutable
class ZigbeeNetwork {
  const ZigbeeNetwork(this.nodes, this.links);

  final List<ZigbeeNode> nodes;
  final List<ZigbeeLink> links;

  ZigbeeNode? node(String ieee) =>
      nodes.where((n) => n.ieee == ieee).firstOrNull;

  /// The router or coordinator a device talks through: its best link to
  /// one (for an end device that is its parent).
  String? parentOf(String ieee) {
    ZigbeeLink? best;
    for (final l in links) {
      if (!l.touches(ieee)) continue;
      final other = node(l.other(ieee));
      if (other == null || other.role == ZigbeeRole.end) continue;
      if (best == null || (l.lqi ?? 0) > (best.lqi ?? 0)) best = l;
    }
    return best?.other(ieee);
  }

  /// Links under [weakLqi], weakest first.
  List<ZigbeeLink> get weakLinks =>
      links.where((l) => l.lqi != null && l.lqi! < weakLqi).toList()
        ..sort((a, b) => a.lqi!.compareTo(b.lqi!));
}

int? _int(Object? v) => switch (v) {
  num() => v.toInt(),
  String() => int.tryParse(v),
  _ => null,
};

ZigbeeRole _role(Object? type) => switch ('$type'.toLowerCase()) {
  'coordinator' => ZigbeeRole.coordinator,
  'router' => ZigbeeRole.router,
  _ => ZigbeeRole.end,
};

/// Keeps one link per pair (the better reported quality).
List<ZigbeeLink> _dedupe(Iterable<ZigbeeLink> links, Set<String> known) {
  final byPair = <String, ZigbeeLink>{};
  for (final l in links) {
    if (l.a == l.b || !known.contains(l.a) || !known.contains(l.b)) continue;
    final key = ([l.a, l.b]..sort()).join('|');
    final old = byPair[key];
    if (old == null || (l.lqi ?? -1) > (old.lqi ?? -1)) byPair[key] = l;
  }
  return byPair.values.toList();
}

/// ZHA's `zha/devices` WebSocket answer: each device with its neighbour
/// table (`neighbors`: ieee, lqi), as the ZHA network visualisation uses.
ZigbeeNetwork parseZhaDevices(Object? json) {
  final nodes = <ZigbeeNode>[];
  final links = <ZigbeeLink>[];
  if (json is List) {
    for (final d in json) {
      if (d is! Map || d['ieee'] is! String) continue;
      final ieee = d['ieee']! as String;
      final name = d['user_given_name'] ?? d['name'];
      nodes.add(
        ZigbeeNode(
          ieee: ieee,
          name: name is String && name.isNotEmpty ? name : ieee,
          role: _role(d['device_type']),
          haDeviceId: d['device_reg_id'] is String
              ? d['device_reg_id']! as String
              : null,
          available: d['available'] != false,
        ),
      );
      for (final n in d['neighbors'] is List ? d['neighbors']! as List : []) {
        if (n is Map && n['ieee'] is String) {
          links.add(ZigbeeLink(ieee, n['ieee']! as String, _int(n['lqi'])));
        }
      }
    }
  }
  return ZigbeeNetwork(nodes, _dedupe(links, {for (final n in nodes) n.ieee}));
}

/// Zigbee2MQTT's `bridge/response/networkmap` (type `raw`): the answer's
/// `data.value` with `nodes` and `links` (`source`/`target`, `lqi` or
/// `linkquality`). [payload] is the MQTT message, JSON text or decoded.
ZigbeeNetwork parseZ2mNetworkMap(Object? payload) {
  final json = payload is String ? jsonDecode(payload) : payload;
  final value = switch (json) {
    {'data': {'value': final Map<Object?, Object?> v}} => v,
    _ => const <Object?, Object?>{},
  };
  final nodes = [
    for (final n in value['nodes'] is List ? value['nodes']! as List : [])
      if (n is Map && n['ieeeAddr'] is String)
        ZigbeeNode(
          ieee: n['ieeeAddr']! as String,
          name: n['friendlyName'] is String
              ? n['friendlyName']! as String
              : n['ieeeAddr']! as String,
          role: _role(n['type']),
          available: n['failed'] is! List || (n['failed']! as List).isEmpty,
        ),
  ];
  String? addr(Object? end) => end is Map ? end['ieeeAddr'] as String? : null;
  final links = [
    for (final l in value['links'] is List ? value['links']! as List : [])
      if (l is Map)
        if ((addr(l['source']), addr(l['target'])) case (
          final String a,
          final String b,
        ))
          ZigbeeLink(a, b, _int(l['lqi'] ?? l['linkquality'])),
  ];
  return ZigbeeNetwork(nodes, _dedupe(links, {for (final n in nodes) n.ieee}));
}

/// Where each device is drawn in a [size] picture: the coordinator in the
/// middle, routers around it, end devices on the outer ring next to the
/// router they talk through.
Map<String, Offset> layoutZigbee(ZigbeeNetwork net, Size size) {
  final center = size.center(Offset.zero);
  final radius = math.min(size.width, size.height) / 2 - 40;
  final out = <String, Offset>{};
  final coordinators = net.nodes.where((n) => n.role == ZigbeeRole.coordinator);
  for (final c in coordinators) {
    out[c.ieee] = center;
  }
  final routers = net.nodes.where((n) => n.role == ZigbeeRole.router).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  final angle = <String, double>{
    for (final c in coordinators) c.ieee: -math.pi / 2,
  };
  for (final (i, r) in routers.indexed) {
    final a = -math.pi / 2 + 2 * math.pi * i / routers.length;
    angle[r.ieee] = a;
    out[r.ieee] = center + Offset.fromDirection(a, radius * 0.5);
  }
  // End devices ordered by their parent's angle, then spread evenly.
  final ends = net.nodes.where((n) => n.role == ZigbeeRole.end).toList()
    ..sort((a, b) {
      final pa = angle[net.parentOf(a.ieee)] ?? 10;
      final pb = angle[net.parentOf(b.ieee)] ?? 10;
      return pa != pb ? pa.compareTo(pb) : a.name.compareTo(b.name);
    });
  for (final (i, e) in ends.indexed) {
    final a = -math.pi / 2 + 2 * math.pi * (i + 0.5) / ends.length;
    out[e.ieee] = center + Offset.fromDirection(a, radius);
  }
  return out;
}

/// The Zigbee network of this Home Assistant (ZHA or Zigbee2MQTT), read
/// once per opening: building the map makes every router report its
/// neighbours, which takes a while on a big network.
final zigbeeNetworkProvider = FutureProvider.autoDispose<ZigbeeNetwork?>((
  ref,
) async {
  final ws = ref.watch(webSocketManagerProvider);
  final api = ref.watch(homeAssistantApiProvider);
  if (ws == null || api == null) return null;
  final backends = await ref.watch(zigbeeBackendsProvider.future);
  if (backends.contains(ZigbeeBackend.zha)) {
    return parseZhaDevices(
      await ws.sendCommand({
        'type': 'zha/devices',
      }, timeout: const Duration(seconds: 60)),
    );
  }
  if (backends.contains(ZigbeeBackend.zigbee2mqtt)) {
    const base = 'zigbee2mqtt';
    // Listen for the answer first, then ask (HA's `mqtt/subscribe`).
    final answer = ws
        .subscribeCommand({
          'type': 'mqtt/subscribe',
          'topic': '$base/bridge/response/networkmap',
        })
        .first
        .timeout(const Duration(seconds: 120));
    await api.callService(
      'mqtt',
      'publish',
      data: {
        'topic': '$base/bridge/request/networkmap',
        'payload': jsonEncode({'type': 'raw', 'routes': false}),
      },
    );
    final event = await answer;
    return parseZ2mNetworkMap(event['payload']);
  }
  return null;
});
