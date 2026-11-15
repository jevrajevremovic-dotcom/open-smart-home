// Checks a new Home Assistant, optionally sets it up, and writes the
// handover report for the customer.
//
//   cd app
//   HA_TOKEN=… dart run tool/provision.dart http://192.168.1.10:8123 \
//       [--areas "Dnevna soba,Kuhinja,Spavaća soba"] \
//       [--time-zone Europe/Belgrade --country RS --currency RSD] \
//       [--apply] [--report zapisnik.md]
//
// Without --apply nothing is changed: it only reads and reports.
// The token comes from HA_TOKEN or is typed (hidden); it is never printed
// or written to the report. Uses only Home Assistant's WebSocket API
// (the commands HA's own frontend uses; administrator token).
// TLS certificates are validated: a self-signed server is reached on the
// home network by its http:// address, or trusted in the app instead.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'provision_lib.dart';

Future<void> main(List<String> args) async {
  String? option(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  const withValue = {
    '--areas',
    '--time-zone',
    '--country',
    '--currency',
    '--report',
  };
  final positional = [
    for (var i = 0; i < args.length; i++)
      if (!args[i].startsWith('--') &&
          (i == 0 || !withValue.contains(args[i - 1])))
        args[i],
  ];
  if (positional.isEmpty || args.contains('--help')) {
    stderr.writeln(
      'Usage: HA_TOKEN=… dart run tool/provision.dart <url> '
      '[--areas "A,B"] [--time-zone Europe/Belgrade] [--country RS] '
      '[--currency RSD] [--apply] [--report file.md]',
    );
    exitCode = 64;
    return;
  }
  final base = Uri.parse(positional.first);
  if (!base.hasScheme || base.host.isEmpty) {
    stderr.writeln('Not a server address: ${positional.first}');
    exitCode = 64;
    return;
  }
  final apply = args.contains('--apply');
  var token = Platform.environment['HA_TOKEN'];
  if (token == null || token.isEmpty) {
    stdout.write('Dugotrajni token (administrator, ne prikazuje se): ');
    stdin.echoMode = false;
    token = stdin.readLineSync()?.trim();
    stdin.echoMode = true;
    stdout.writeln();
  }
  if (token == null || token.isEmpty) {
    stderr.writeln('No token.');
    exitCode = 64;
    return;
  }

  final ws = _Ha(base);
  try {
    await ws.connect(token);
    Future<List<Map<String, Object?>>> list(String type) async => [
      for (final e in (await ws.command({'type': type}) as List? ?? const []))
        if (e is Map) e.cast<String, Object?>(),
    ];
    final config = (await ws.command({'type': 'get_config'}) as Map)
        .cast<String, Object?>();
    stdout.writeln(
      'Home Assistant ${config['version']} – ${config['location_name']}',
    );

    // Setup, only with --apply.
    final wanted = (option('areas') ?? '').split(',');
    final missing = missingAreas(
      await list('config/area_registry/list'),
      wanted,
    );
    final core = coreChanges(
      config,
      timeZone: option('time-zone'),
      country: option('country'),
      currency: option('currency'),
    );
    for (final a in missing) {
      stdout.writeln('${apply ? 'Pravim' : 'Napravio bih'} prostoriju: $a');
      if (apply) {
        await ws.command({'type': 'config/area_registry/create', 'name': a});
      }
    }
    if (core.isNotEmpty) {
      stdout.writeln('${apply ? 'Menjam' : 'Promenio bih'}: $core');
      if (apply) await ws.command({'type': 'config/core/update', ...core});
    }

    Map<String, Object?>? backup;
    try {
      backup = (await ws.command({'type': 'backup/config/info'}) as Map)
          .cast<String, Object?>();
    } on Object {
      backup = null; // no backup integration (HA before 2025.1)
    }
    final data = ProvisionData(
      config: apply
          ? (await ws.command({'type': 'get_config'}) as Map)
                .cast<String, Object?>()
          : config,
      states: await list('get_states'),
      areas: await list('config/area_registry/list'),
      devices: await list('config/device_registry/list'),
      entities: await list('config/entity_registry/list'),
      entries: await list('config_entries/get'),
      backup: backup,
    );
    for (final c in handoverChecks(data)) {
      stdout.writeln('${c.ok ? '  OK ' : '  !! '} ${c.text}');
    }
    final report = option('report');
    if (report != null) {
      await File(report)
          .writeAsString(handoverReport(data, DateTime.now(), host: base.host));
      stdout.writeln('Zapisnik: $report');
    }
  } on _HaError catch (e) {
    stderr.writeln(e.message);
    exitCode = 1;
  } on SocketException catch (e) {
    stderr.writeln('Server se ne javlja: ${e.message}');
    exitCode = 1;
  } on HandshakeException {
    stderr.writeln(
      'TLS sertifikat nije validan. Na kućnoj mreži koristite http:// adresu.',
    );
    exitCode = 1;
  } finally {
    await ws.close();
  }
}

class _HaError implements Exception {
  _HaError(this.message);
  final String message;
}

/// The smallest Home Assistant WebSocket client: auth, then commands.
class _Ha {
  _Ha(this.base);

  final Uri base;
  WebSocket? _socket;
  StreamIterator<Object?>? _in;
  var _id = 0;

  Future<Map<Object?, Object?>> _next() async {
    final it = _in!;
    if (!await it.moveNext().timeout(const Duration(seconds: 30))) {
      throw _HaError('Veza je prekinuta.');
    }
    return jsonDecode(it.current! as String) as Map<Object?, Object?>;
  }

  Future<void> connect(String token) async {
    final uri = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/api/websocket',
    );
    _socket = await WebSocket.connect(uri.toString());
    _in = StreamIterator(_socket!);
    await _next(); // auth_required
    _socket!.add(jsonEncode({'type': 'auth', 'access_token': token}));
    final reply = await _next();
    if (reply['type'] != 'auth_ok') {
      throw _HaError('Token nije prihvaćen.');
    }
  }

  Future<Object?> command(Map<String, Object?> message) async {
    final id = ++_id;
    _socket!.add(jsonEncode({'id': id, ...message}));
    while (true) {
      final reply = await _next();
      if (reply['id'] != id) continue;
      if (reply['success'] != true) {
        final error = reply['error'];
        throw _HaError(
          '${message['type']}: '
          '${error is Map ? error['message'] : 'nije uspelo'}',
        );
      }
      return reply['result'];
    }
  }

  Future<void> close() async {
    await _socket?.close();
  }
}
