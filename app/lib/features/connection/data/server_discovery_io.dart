import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nsd/nsd.dart' as nsd;

import '../../../core/logging/app_logger.dart';
import 'server_discovery.dart';

ServerDiscovery createPlatformServerDiscovery() => NsdServerDiscovery();

/// System service discovery: Android `NsdManager`, Apple Bonjour.
class NsdServerDiscovery implements ServerDiscovery {
  static final _log = AppLogger('Discovery');

  @override
  bool get isSupported =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows;

  @override
  Stream<List<DiscoveredServer>> discover() {
    nsd.Discovery? discovery;
    final found = <String, DiscoveredServer>{};
    late final StreamController<List<DiscoveredServer>> controller;

    void onService(nsd.Service service, nsd.ServiceStatus status) {
      final server = discoveredServerFrom(
        serviceName: service.name,
        host: service.host,
        port: service.port,
        ipv4Addresses: [
          for (final a in service.addresses ?? const <InternetAddress>[])
            if (a.type == InternetAddressType.IPv4) a.address,
        ],
        txt: {
          for (final e in (service.txt ?? const {}).entries)
            e.key: e.value == null
                ? null
                : utf8.decode(e.value!, allowMalformed: true),
        },
      );
      if (server == null) return;
      if (status == nsd.ServiceStatus.found) {
        found[server.key] = server;
      } else {
        found.remove(server.key);
      }
      if (!controller.isClosed) controller.add(List.unmodifiable(found.values));
    }

    controller = StreamController<List<DiscoveredServer>>(
      onListen: () async {
        try {
          discovery = await nsd.startDiscovery(
            homeAssistantServiceType,
            ipLookupType: nsd.IpLookupType.v4,
          );
          discovery!.addServiceListener(onService);
        } on Object catch (e) {
          // Missing plugin (desktop/tests) or OS refusal: discovery is a
          // convenience, manual entry always works.
          _log.warning('mDNS discovery unavailable', e.runtimeType);
          if (!controller.isClosed) await controller.close();
        }
      },
      onCancel: () async {
        final d = discovery;
        discovery = null;
        if (d != null) {
          try {
            await nsd.stopDiscovery(d);
          } on Object catch (e) {
            _log.debug('stopDiscovery failed: ${e.runtimeType}');
          }
        }
      },
    );
    return controller.stream;
  }
}
