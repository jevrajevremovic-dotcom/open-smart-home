import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../../integrations/home_assistant/websocket/connection_status.dart';
import '../../authentication/application/session_controller.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/data/home_state_repository.dart';
import '../application/live_events_controller.dart';

/// MVP phase-1 home: connection health, server info and the live event
/// feed. Replaced by the real dashboard in phase 6.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(serverConfigProvider);
    final title = switch (config) {
      AsyncData(:final value?) => value.locationName,
      _ => context.l10n.appTitle,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: _StatusIndicator(),
          ),
        ],
      ),
      body: MockModeBanner(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                WindowSize.fromWidth(constraints.maxWidth) !=
                WindowSize.compact;
            const overview = _OverviewCard();
            const events = _LiveEventsCard();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: wide
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: SingleChildScrollView(child: overview)),
                        SizedBox(width: 16),
                        Expanded(child: events),
                      ],
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        overview,
                        SizedBox(height: 16),
                        Expanded(child: events),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusIndicator extends ConsumerWidget {
  const _StatusIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status =
        ref.watch(connectionStatusProvider).value ?? HaConnectionStatus.initial;
    return ConnectionStatusChip(status: status);
  }
}

class _OverviewCard extends ConsumerWidget {
  const _OverviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status =
        ref.watch(connectionStatusProvider).value ?? HaConnectionStatus.initial;
    final profile = ref.watch(activeProfileProvider);
    final config = ref.watch(serverConfigProvider);
    final deviceCount = ref.watch(
      visibleDeviceIdsProvider.select((ids) => ids.length),
    );
    final roomCount = ref.watch(roomsProvider.select((r) => r.length));
    final sync = ref.watch(
      homeSnapshotProvider.select((s) => (s.status, s.lastSyncedAt)),
    );
    final failure = status.failure;

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  profile.address.isSecure
                      ? Icons.lock_outline
                      : Icons.lan_outlined,
                ),
                title: Text(profile.address.toString()),
                subtitle: switch (config) {
                  AsyncData(:final value?) => Text(
                    l10n.serverVersion(value.version),
                  ),
                  AsyncError(:final error) => Text(_describe(l10n, error)),
                  _ => null,
                },
              ),
            if (sync.$1 == SyncStatus.syncing && deviceCount == 0)
              const LinearProgressIndicator()
            else if (deviceCount > 0)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.devices_other_outlined),
                title: Text(l10n.devicesInRooms(deviceCount, roomCount)),
              ),
            if (sync.$1 == SyncStatus.stale && sync.$2 != null) ...[
              const SizedBox(height: 8),
              InlineNotice.warning(
                l10n.dataStaleSince(
                  DateFormat.Hm(Localizations.localeOf(context).toLanguageTag())
                      .format(sync.$2!),
                ),
              ),
            ],
            if (!status.isConnected && failure != null) ...[
              const SizedBox(height: 8),
              InlineNotice.warning(failureMessage(l10n, failure)),
            ],
            if (!status.isConnected &&
                status.state != HaConnectionState.connecting) ...[
              const SizedBox(height: 12),
              status.isTerminal
                  ? FilledButton.icon(
                      onPressed: () => ref
                          .read(sessionControllerProvider.notifier)
                          .signOut(),
                      icon: const Icon(Icons.login),
                      label: Text(l10n.signInAgain),
                    )
                  : OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(webSocketManagerProvider)?.retryNow(),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retryNow),
                    ),
            ],
            const SizedBox(height: 12),
            InlineNotice.info(l10n.homeComingSoon),
          ],
        ),
      ),
    );
  }

  static String _describe(AppLocalizations l10n, Object error) =>
      error is AppFailure ? failureMessage(l10n, error) : l10n.failureUnknown;
}

class _LiveEventsCard extends ConsumerWidget {
  const _LiveEventsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final events = ref.watch(liveEventsProvider);
    final time = DateFormat.Hms(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.liveEventsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.liveEventsEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, i) {
                      final e = events[i];
                      final updated = e.newState?.lastUpdated?.toLocal();
                      return ListTile(
                        dense: true,
                        title: Text(e.newState?.friendlyName ?? e.entityId),
                        subtitle: Text(
                          '${e.oldState?.state ?? '—'} → ${e.newState?.state ?? '—'}',
                        ),
                        trailing: updated == null
                            ? null
                            : Text(time.format(updated)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
