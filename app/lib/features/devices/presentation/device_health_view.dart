import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import 'device_presentation.dart';
import '../application/device_health.dart';
import '../domain/device_kind.dart';
import '../domain/smart_home_device.dart';

/// What to do about [issue], for this kind of connection.
String healthAdvice(
  AppLocalizations l10n,
  SmartHomeDevice device,
  HealthIssue issue,
) {
  final p = device.protocol;
  final mesh = const {
    DeviceProtocol.zigbee,
    DeviceProtocol.zwave,
    DeviceProtocol.thread,
  }.contains(p);
  final wifi = p == DeviceProtocol.wifi || p == DeviceProtocol.esphome;
  final battery =
      device.metadata.batteryPercent != null ||
      device.metadata.batteryLow != null;
  return switch (issue) {
    HealthIssue.offline when battery => l10n.healthAdviceOfflineBattery,
    HealthIssue.offline when mesh => l10n.healthAdviceOfflineMesh,
    HealthIssue.offline when wifi => l10n.healthAdviceOfflineWifi,
    HealthIssue.offline when p == DeviceProtocol.cloud =>
      l10n.healthAdviceOfflineCloud,
    HealthIssue.offline when p == DeviceProtocol.bluetooth =>
      l10n.healthAdviceOfflineBluetooth,
    HealthIssue.offline => l10n.healthAdviceOfflineGeneric,
    HealthIssue.weakSignal when mesh => l10n.healthAdviceWeakMesh,
    HealthIssue.weakSignal when p == DeviceProtocol.bluetooth =>
      l10n.healthAdviceOfflineBluetooth,
    HealthIssue.weakSignal => l10n.healthAdviceWeakWifi,
    HealthIssue.flaky => l10n.healthAdviceFlaky,
    HealthIssue.lowBattery => l10n.healthAdviceLowBattery,
  };
}

String healthIssueLabel(
  AppLocalizations l10n,
  HealthIssue issue,
  DeviceHealth health,
) => switch (issue) {
  HealthIssue.offline => l10n.healthOffline,
  HealthIssue.flaky => l10n.healthFlaky(health.outages),
  HealthIssue.weakSignal => l10n.healthWeakSignal,
  HealthIssue.lowBattery => l10n.healthLowBattery,
};

/// "Why doesn't it work?" on the device screen: the problems found, each
/// with what to do; or one quiet line when all is well.
class DeviceHealthSection extends ConsumerWidget {
  const DeviceHealthSection({super.key, required this.device});

  final SmartHomeDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.statusColors;
    final health = ref.watch(deviceHealthProvider(device.id)).value;
    if (health == null) return const SizedBox.shrink();
    if (health.ok) {
      return Row(
        key: const Key('deviceHealthOk'),
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: colors.ok),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              health.outages == 0
                  ? l10n.healthOk
                  : l10n.healthOutages(health.outages),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }
    final locale = l10n.localeName;
    return Card.outlined(
      key: const Key('deviceHealth'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.healing_outlined, color: colors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.healthTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (health.offlineSince case final since?) ...[
              const SizedBox(height: 4),
              Text(
                l10n.healthOfflineSince(formatDateTime(locale, since)),
                style: theme.textTheme.bodySmall,
              ),
            ],
            for (final issue in health.issues) ...[
              const SizedBox(height: 12),
              Text(
                healthIssueLabel(l10n, issue, health),
                key: ValueKey('healthIssue-${issue.name}'),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(healthAdvice(l10n, device, issue)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Every device that is offline or barely reachable, across the home.
Future<void> showDeviceHealth(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _HealthSheet(),
    );

class _HealthSheet extends ConsumerWidget {
  const _HealthSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.statusColors;
    final devices = ref.watch(unhealthyDevicesProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        key: const Key('healthSheet'),
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(l10n.healthListTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          if (devices.isEmpty)
            Text(l10n.healthListNone, key: const Key('healthNone')),
          for (final d in devices)
            ListTile(
              key: ValueKey('health-${d.id}'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                d.available
                    ? Icons.network_wifi_1_bar
                    : Icons.portable_wifi_off,
                color: d.available ? colors.warning : colors.critical,
              ),
              title: Text(d.name),
              subtitle: Text(
                d.available ? l10n.healthWeakSignal : l10n.healthOffline,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.device(d.id));
              },
            ),
        ],
      ),
    );
  }
}
