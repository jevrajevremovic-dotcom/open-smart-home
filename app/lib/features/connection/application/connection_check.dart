import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/local_network.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../integrations/home_assistant/api/dio_home_assistant_api.dart'
    show AccessTokenReader;
import '../../../integrations/home_assistant/api/home_assistant_api.dart';
import '../../../integrations/home_assistant/home_assistant_providers.dart';
import '../../authentication/data/server_profile.dart';

/// What the connection check looks at, in order.
enum CheckStep { network, home, remote, signIn }

enum CheckOutcome { running, ok, failed, skipped }

@immutable
class CheckLine {
  const CheckLine(this.step, this.outcome, {this.failure, this.notHa = false});

  final CheckStep step;
  final CheckOutcome outcome;
  final FailureKind? failure;

  /// Something answered at the address, but not Home Assistant.
  final bool notHa;
}

/// Checks step by step why Home Assistant cannot be reached: is the phone
/// on a network, does the home (and the remote) address answer like
/// Home Assistant, is the sign-in still valid. [onLine] reports each
/// step as it starts and ends.
Future<List<CheckLine>> runConnectionCheck({
  required ServerProfile profile,
  required HomeAssistantApiFactory apiFor,
  required AccessTokenReader token,
  required LocalNetwork network,
  void Function(CheckLine line)? onLine,
}) async {
  final lines = <CheckLine>[];
  void put(CheckLine l) {
    lines
      ..removeWhere((x) => x.step == l.step)
      ..add(l);
    onLine?.call(l);
  }

  put(const CheckLine(CheckStep.network, CheckOutcome.running));
  put(switch (await network.hasNetwork()) {
    true => const CheckLine(CheckStep.network, CheckOutcome.ok),
    false => const CheckLine(CheckStep.network, CheckOutcome.failed),
    null => const CheckLine(CheckStep.network, CheckOutcome.skipped),
  });

  Future<HomeAssistantApi?> probe(CheckStep step, ServerProfile p) async {
    put(CheckLine(step, CheckOutcome.running));
    final api = apiFor(p, token);
    try {
      final result = await api.probe();
      if (result == ServerProbeResult.reachableRequiresAuth) {
        put(CheckLine(step, CheckOutcome.ok));
        return api;
      }
      put(CheckLine(step, CheckOutcome.failed, notHa: true));
    } on AppFailure catch (e) {
      put(CheckLine(step, CheckOutcome.failed, failure: e.kind));
    }
    api.close();
    return null;
  }

  final home = await probe(CheckStep.home, profile);
  final remoteAddress = profile.remoteAddress;
  final remote = remoteAddress == null
      ? null
      : await probe(CheckStep.remote, profile.via(remoteAddress));
  if (remoteAddress == null) {
    put(const CheckLine(CheckStep.remote, CheckOutcome.skipped));
  }

  final reached = home ?? remote;
  if (reached == null) {
    put(const CheckLine(CheckStep.signIn, CheckOutcome.skipped));
  } else {
    put(const CheckLine(CheckStep.signIn, CheckOutcome.running));
    try {
      await reached.verifyAccessToken();
      put(const CheckLine(CheckStep.signIn, CheckOutcome.ok));
    } on AppFailure catch (e) {
      put(CheckLine(CheckStep.signIn, CheckOutcome.failed, failure: e.kind));
    }
  }
  home?.close();
  remote?.close();
  return lines;
}

/// The MAC address of the server's network card for Wake-on-LAN, per
/// server (not secret; kept with the app's settings).
class WakeMacController extends Notifier<String?> {
  WakeMacController(this.profileId);

  final String profileId;

  String get _key => 'wol::$profileId';

  @override
  String? build() =>
      ref.watch(appPreferencesProvider).readJson(_key)?['mac'] as String?;

  Future<void> set(String? mac) async {
    state = mac;
    await ref
        .read(appPreferencesProvider)
        .writeJson(_key, mac == null ? null : {'mac': mac});
  }
}

final wakeMacProvider =
    NotifierProvider.family<WakeMacController, String?, String>(
      WakeMacController.new,
    );
