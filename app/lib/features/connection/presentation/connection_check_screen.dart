import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/local_network.dart';
import '../../../core/widgets/responsive.dart';
import '../../../integrations/home_assistant/home_assistant_providers.dart';
import '../../authentication/application/session_controller.dart';
import '../application/connection_check.dart';

/// "Why is there no connection?": the phone's network, the home and the
/// remote address, the sign-in — each with what to do about it. And, if
/// set up, waking the server over the network.
class ConnectionCheckScreen extends ConsumerStatefulWidget {
  const ConnectionCheckScreen({super.key});

  @override
  ConsumerState<ConnectionCheckScreen> createState() =>
      _ConnectionCheckScreenState();
}

class _ConnectionCheckScreenState extends ConsumerState<ConnectionCheckScreen> {
  final Map<CheckStep, CheckLine> _lines = {};
  bool _running = false;
  final _mac = TextEditingController();

  @override
  void initState() {
    super.initState();
    final id = ref.read(activeProfileProvider)?.id;
    if (id != null) _mac.text = ref.read(wakeMacProvider(id)) ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _mac.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final profile = ref.read(activeProfileProvider);
    final tokens = ref.read(accessTokenManagerProvider);
    if (profile == null || tokens == null || _running) return;
    setState(() {
      _running = true;
      _lines.clear();
    });
    await runConnectionCheck(
      profile: profile,
      apiFor: ref.read(homeAssistantApiFactoryProvider),
      token: tokens.accessToken,
      network: ref.read(localNetworkProvider),
      onLine: (l) {
        if (mounted) setState(() => _lines[l.step] = l);
      },
    );
    if (mounted) setState(() => _running = false);
  }

  Future<void> _wake() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final mac = parseMac(_mac.text);
    final id = ref.read(activeProfileProvider)?.id;
    if (mac == null || id == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.wolBadMac)));
      return;
    }
    await ref.read(wakeMacProvider(id).notifier).set(_mac.text.trim());
    try {
      await ref.read(localNetworkProvider).wake(mac);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.wolSent)));
    } on Object {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.wolFailed)));
    }
  }

  String _title(AppLocalizations l10n, CheckStep s) => switch (s) {
    CheckStep.network => l10n.checkNetwork,
    CheckStep.home => l10n.checkHome,
    CheckStep.remote => l10n.checkRemote,
    CheckStep.signIn => l10n.checkSignIn,
  };

  /// What to do when [l] failed (or why it was skipped).
  String? _hint(AppLocalizations l10n, CheckLine l) {
    if (l.outcome == CheckOutcome.skipped) {
      return switch (l.step) {
        CheckStep.remote => l10n.checkRemoteNone,
        CheckStep.signIn => l10n.checkSignInSkipped,
        _ => null,
      };
    }
    if (l.outcome != CheckOutcome.failed) return null;
    if (l.notHa) return l10n.checkNotHa;
    return switch ((l.step, l.failure)) {
      (CheckStep.network, _) => l10n.checkNetworkFix,
      (_, FailureKind.certificate) => l10n.checkCertificate,
      (CheckStep.home, _) => l10n.checkHomeFix,
      (CheckStep.remote, _) => l10n.checkRemoteFix,
      (CheckStep.signIn, FailureKind.authentication) => l10n.checkSignInFix,
      (CheckStep.signIn, _) => l10n.checkSignInOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final lines = [for (final s in CheckStep.values) ?_lines[s]];
    final done = !_running && lines.length == CheckStep.values.length;
    bool failed(CheckStep s) => _lines[s]?.outcome == CheckOutcome.failed;
    final allOk =
        done &&
        lines.every((l) => l.outcome != CheckOutcome.failed) &&
        _lines[CheckStep.signIn]?.outcome == CheckOutcome.ok;
    final serverDown =
        done &&
        failed(CheckStep.home) &&
        _lines[CheckStep.home]?.notHa == false &&
        _lines[CheckStep.home]?.failure != FailureKind.certificate;
    final canWake = ref.watch(localNetworkProvider).canWake;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ConstrainedContent(
            maxWidth: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final l in lines)
                  ListTile(
                    key: ValueKey('check-${l.step.name}'),
                    contentPadding: EdgeInsets.zero,
                    leading: switch (l.outcome) {
                      CheckOutcome.running => const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      CheckOutcome.ok => Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                      CheckOutcome.failed => Icon(
                        Icons.error,
                        color: theme.colorScheme.error,
                      ),
                      CheckOutcome.skipped => Icon(
                        Icons.remove_circle_outline,
                        color: theme.colorScheme.outline,
                      ),
                    },
                    title: Text(_title(l10n, l.step)),
                    subtitle: switch (_hint(l10n, l)) {
                      final h? => Text(h),
                      null => null,
                    },
                  ),
                const SizedBox(height: 12),
                if (allOk)
                  Text(
                    l10n.checkAllOk,
                    key: const Key('checkAllOk'),
                    style: theme.textTheme.titleSmall,
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    if (failed(CheckStep.signIn))
                      FilledButton.icon(
                        onPressed: () => ref
                            .read(sessionControllerProvider.notifier)
                            .signOut(),
                        icon: const Icon(Icons.login),
                        label: Text(l10n.signInAgain),
                      ),
                    OutlinedButton.icon(
                      key: const Key('checkAgain'),
                      onPressed: _running
                          ? null
                          : () {
                              ref.read(webSocketManagerProvider)?.retryNow();
                              _check();
                            },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.checkAgain),
                    ),
                  ],
                ),
                if (canWake) ...[
                  const Divider(height: 40),
                  Text(l10n.wolTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    serverDown ? l10n.wolHintDown : l10n.wolHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('wolMac'),
                    controller: _mac,
                    decoration: InputDecoration(
                      labelText: l10n.wolMac,
                      hintText: 'AA:BB:CC:DD:EE:FF',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.tonalIcon(
                      key: const Key('wolWake'),
                      onPressed: _wake,
                      icon: const Icon(Icons.power_settings_new),
                      label: Text(l10n.wolWake),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
