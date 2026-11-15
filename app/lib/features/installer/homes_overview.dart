import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/storage/credential_store.dart';
import '../../integrations/home_assistant/api/dio_home_assistant_api.dart'
    show AccessTokenReader;
import '../../integrations/home_assistant/home_assistant_providers.dart';
import '../../integrations/home_assistant/models/ha_models.dart';
import '../authentication/application/access_token_manager.dart';
import '../authentication/application/session_controller.dart';
import '../authentication/data/server_profile.dart';

/// How a home is doing, at a glance.
enum HomeLevel { ok, attention, down }

/// A backup older than this needs a look.
const backupMaxAge = Duration(days: 3);

/// What the installer sees per home. Read straight from that home's Home
/// Assistant with its own stored sign-in; nothing goes anywhere else.
@immutable
class HomeHealth {
  const HomeHealth({
    required this.name,
    required this.profile,
    this.failure,
    this.viaRemote = false,
    this.haVersion,
    this.unavailable = const [],
    this.lowBatteries = const [],
    this.updates = const [],
    this.lastBackup,
    this.backupKnown = false,
  });

  final String name;
  final ServerProfile profile;

  /// Why it could not be read (network, sign-in…); `null` = read.
  final FailureKind? failure;

  /// Reached through the remote address (the home one did not answer).
  final bool viaRemote;
  final String? haVersion;

  /// Names of entities Home Assistant reports as unavailable.
  final List<String> unavailable;

  /// `name (12 %)` of batteries at or under 15 %.
  final List<String> lowBatteries;

  /// Names of pending updates (HA, add-ons, device firmware).
  final List<String> updates;

  /// Last successful automatic backup (HA's backup integration).
  final DateTime? lastBackup;

  /// Home Assistant has the backup sensors at all (2025.1 and newer).
  final bool backupKnown;

  bool backupOld(DateTime now) =>
      !backupKnown ||
      lastBackup == null ||
      now.difference(lastBackup!) > backupMaxAge;

  HomeLevel level(DateTime now) {
    if (failure != null) return HomeLevel.down;
    if (unavailable.isNotEmpty || lowBatteries.isNotEmpty || backupOld(now)) {
      return HomeLevel.attention;
    }
    return HomeLevel.ok;
  }
}

/// Domains whose "unavailable" is not a broken device.
const _notDevices = {
  'automation',
  'button',
  'conversation',
  'event',
  'image',
  'scene',
  'script',
  'stt',
  'tts',
  'update',
  'zone',
};

/// The counts of [HomeHealth] from a home's `/api/states`.
HomeHealth summarizeHome(
  String name,
  ServerProfile profile,
  List<HaEntityState> states, {
  String? haVersion,
  bool viaRemote = false,
}) {
  String label(HaEntityState s) => switch (s.attributes['friendly_name']) {
    final String n when n.isNotEmpty => n,
    _ => s.entityId,
  };
  final unavailable = <String>[];
  final low = <String>[];
  final updates = <String>[];
  DateTime? backup;
  var backupKnown = false;
  for (final s in states) {
    final domain = s.entityId.split('.').first;
    if (s.state == 'unavailable' && !_notDevices.contains(domain)) {
      unavailable.add(label(s));
      continue;
    }
    if (domain == 'update' && s.state == 'on') updates.add(label(s));
    final battery = s.attributes['device_class'] == 'battery';
    if (battery && domain == 'sensor') {
      final v = double.tryParse(s.state);
      if (v != null && v <= 15) low.add('${label(s)} (${v.round()} %)');
    } else if (battery && domain == 'binary_sensor' && s.state == 'on') {
      low.add(label(s));
    }
    if (domain == 'sensor' &&
        s.entityId.startsWith('sensor.backup_') &&
        s.entityId.endsWith('last_successful_automatic_backup')) {
      backupKnown = true;
      backup = DateTime.tryParse(s.state)?.toLocal();
    }
  }
  return HomeHealth(
    name: name,
    profile: profile,
    viaRemote: viaRemote,
    haVersion: haVersion,
    unavailable: unavailable..sort(),
    lowBatteries: low..sort(),
    updates: updates..sort(),
    lastBackup: backup,
    backupKnown: backupKnown,
  );
}

/// Reads one home: its home address first, the remote one if that is
/// silent (the installer is usually not at the customer's).
Future<HomeHealth> checkHome(
  String name,
  ServerProfile profile, {
  required HomeAssistantApiFactory apiFor,
  required AccessTokenReader token,
}) async {
  Future<HomeHealth> read(ServerProfile via, {required bool remote}) async {
    final api = apiFor(via, token);
    try {
      final config = await api.fetchConfig();
      final states = await api.fetchStates();
      return summarizeHome(
        name,
        profile,
        states,
        haVersion: config.version,
        viaRemote: remote,
      );
    } finally {
      api.close();
    }
  }

  try {
    return await read(profile, remote: false);
  } on AppFailure catch (e) {
    final remote = profile.remoteAddress;
    final network =
        e.kind == FailureKind.network || e.kind == FailureKind.timeout;
    if (remote != null && network) {
      try {
        return await read(profile.via(remote), remote: true);
      } on AppFailure catch (e2) {
        return HomeHealth(name: name, profile: profile, failure: e2.kind);
      }
    }
    return HomeHealth(name: name, profile: profile, failure: e.kind);
  }
}

/// Every saved home, checked side by side; most urgent first.
final homesOverviewProvider = FutureProvider.autoDispose<List<HomeHealth>>((
  ref,
) async {
  final homes = await ref.watch(savedHomesProvider.future);
  final store = ref.watch(credentialStoreProvider);
  final authClients = ref.watch(haAuthClientFactoryProvider);
  final apiFor = ref.watch(homeAssistantApiFactoryProvider);
  final results = await Future.wait([
    for (final h in homes)
      checkHome(
        h.name,
        h.profile,
        apiFor: apiFor,
        token: AccessTokenManager(
          serverId: h.profile.id,
          store: store,
          authClient: () => authClients(h.profile),
        ).accessToken,
      ),
  ]);
  final now = DateTime.now();
  return results..sort((a, b) {
    final l = b.level(now).index.compareTo(a.level(now).index);
    return l != 0 ? l : a.name.compareTo(b.name);
  });
});
