import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_network_io.dart'
    if (dart.library.js_interop) 'local_network_web.dart';

/// The little the connection check needs from the phone's own network.
abstract interface class LocalNetwork {
  /// Whether the phone has any network address besides loopback;
  /// `null` where that cannot be known (the browser).
  Future<bool?> hasNetwork();

  /// Wake-on-LAN is possible here (not in a browser).
  bool get canWake;

  /// Sends a Wake-on-LAN "magic packet" for [mac] as a broadcast on the
  /// home network (UDP port 9). Nothing is answered; the server just
  /// starts if its network card is set up for it.
  Future<void> wake(List<int> mac);
}

final localNetworkProvider = Provider<LocalNetwork>(
  (ref) => createLocalNetwork(),
);

/// `AA:BB:CC:DD:EE:FF` (or with `-`, or without separators) as six bytes;
/// `null` when it is not a MAC address.
List<int>? parseMac(String text) {
  final hex = text.trim().replaceAll(RegExp('[:-]'), '');
  if (!RegExp(r'^[0-9a-fA-F]{12}$').hasMatch(hex)) return null;
  return [
    for (var i = 0; i < 12; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];
}

/// Six `0xFF` bytes, then the address sixteen times.
List<int> magicPacket(List<int> mac) => [
  for (var i = 0; i < 6; i++) 0xFF,
  for (var i = 0; i < 16; i++) ...mac,
];
