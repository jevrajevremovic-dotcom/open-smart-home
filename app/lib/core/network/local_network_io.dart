import 'dart:io';

import 'local_network.dart';

LocalNetwork createLocalNetwork() => _IoNetwork();

class _IoNetwork implements LocalNetwork {
  @override
  Future<bool?> hasNetwork() async {
    try {
      final interfaces = await NetworkInterface.list();
      return interfaces.any((i) => i.addresses.any((a) => !a.isLoopback));
    } on Object {
      return null;
    }
  }

  @override
  bool get canWake => true;

  @override
  Future<void> wake(List<int> mac) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    try {
      socket.broadcastEnabled = true;
      final packet = magicPacket(mac);
      // Twice: a single UDP packet is easily lost on Wi-Fi.
      for (var i = 0; i < 2; i++) {
        socket.send(packet, InternetAddress('255.255.255.255'), 9);
      }
    } finally {
      socket.close();
    }
  }
}
