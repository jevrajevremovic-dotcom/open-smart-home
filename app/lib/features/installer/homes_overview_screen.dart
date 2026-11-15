import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/localization/l10n.dart';
import '../../app/router/app_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/app_failure.dart';
import '../../core/widgets/responsive.dart';
import '../authentication/application/session_controller.dart';
import 'homes_overview.dart';

Future<void> showHomesOverview(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => const HomesOverviewScreen()));

/// For the installer: all saved homes, how each is doing, the most urgent
/// first. Each home is read with its own sign-in, straight from its Home
/// Assistant (through its remote address when away).
class HomesOverviewScreen extends ConsumerWidget {
  const HomesOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final homes = ref.watch(homesOverviewProvider);
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homesOverviewTitle),
        actions: [
          IconButton(
            key: const Key('homesOverviewRefresh'),
            tooltip: l10n.checkAgain,
            onPressed: homes.isLoading
                ? null
                : () => ref.invalidate(homesOverviewProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: switch (homes) {
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ConstrainedContent(
              maxWidth: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.homesOverviewSummary(
                      value.length,
                      value.where((h) => h.level(now) == HomeLevel.ok).length,
                      value
                          .where((h) => h.level(now) == HomeLevel.attention)
                          .length,
                      value.where((h) => h.level(now) == HomeLevel.down).length,
                    ),
                    key: const Key('homesOverviewSummary'),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.homesOverviewHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final h in value) _HomeCard(health: h, now: now),
                ],
              ),
            ),
          ],
        ),
        AsyncError() => Center(child: Text(l10n.homesOverviewFailed)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _HomeCard extends ConsumerWidget {
  const _HomeCard({required this.health, required this.now});

  final HomeHealth health;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final status = context.statusColors;
    final h = health;
    final level = h.level(now);
    final (icon, color, label) = switch (level) {
      HomeLevel.ok => (Icons.check_circle, status.ok, l10n.homeLevelOk),
      HomeLevel.attention => (
        Icons.warning_amber_rounded,
        status.warning,
        l10n.homeLevelAttention,
      ),
      HomeLevel.down => (Icons.error, status.critical, l10n.homeLevelDown),
    };
    final active = ref.watch(activeProfileProvider)?.id == h.profile.id;
    final date = DateFormat.yMd(l10n.localeName).add_Hm();

    Widget line(IconData i, String text, {Color? tint}) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(i, size: 18, color: tint ?? theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
    String list(List<String> names) => names.length <= 3
        ? names.join(', ')
        : '${names.take(3).join(', ')} ${l10n.homesAndMore(names.length - 3)}';

    return Card.outlined(
      key: ValueKey('homeHealth-${h.profile.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(h.name, style: theme.textTheme.titleMedium),
                ),
                Text(label, style: theme.textTheme.labelLarge),
              ],
            ),
            Text(
              [
                h.profile.address.host,
                if (h.viaRemote) l10n.homesViaRemote,
                if (h.haVersion != null) 'Home Assistant ${h.haVersion}',
              ].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (h.failure != null)
              line(Icons.cloud_off, switch (h.failure) {
                FailureKind.authentication ||
                FailureKind.authorization => l10n.homesSignInExpired,
                FailureKind.certificate => l10n.checkCertificate,
                _ => l10n.homesUnreachable,
              }, tint: status.critical)
            else ...[
              if (h.unavailable.isNotEmpty)
                line(
                  Icons.link_off,
                  l10n.homesUnavailable(
                    h.unavailable.length,
                    list(h.unavailable),
                  ),
                  tint: status.warning,
                ),
              if (h.lowBatteries.isNotEmpty)
                line(
                  Icons.battery_alert,
                  l10n.homesLowBatteries(list(h.lowBatteries)),
                  tint: status.warning,
                ),
              line(
                Icons.backup_outlined,
                !h.backupKnown
                    ? l10n.homesBackupUnknown
                    : h.lastBackup == null
                    ? l10n.homesBackupNever
                    : l10n.homesBackupAt(date.format(h.lastBackup!)),
                tint: h.backupOld(now) ? status.warning : null,
              ),
              if (h.updates.isNotEmpty)
                line(
                  Icons.system_update_alt,
                  l10n.homesUpdates(h.updates.length, list(h.updates)),
                ),
              if (level == HomeLevel.ok &&
                  h.unavailable.isEmpty &&
                  h.lowBatteries.isEmpty)
                line(Icons.devices_other, l10n.homesAllDevicesOk),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: active
                  ? Text(l10n.homesActive, style: theme.textTheme.labelMedium)
                  : TextButton(
                      key: ValueKey('homeOpen-${h.profile.id}'),
                      onPressed: () async {
                        final router = GoRouter.of(context);
                        Navigator.of(context).pop();
                        await ref
                            .read(sessionControllerProvider.notifier)
                            .switchTo(h.profile);
                        router.go(AppRoutes.home);
                      },
                      child: Text(l10n.homesOpen),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
