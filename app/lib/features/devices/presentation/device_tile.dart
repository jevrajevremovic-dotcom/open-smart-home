import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../application/device_providers.dart';
import '../domain/device_command.dart';
import '../domain/smart_home_device.dart';
import 'device_actions.dart';
import 'device_presentation.dart';

/// Compact card for one device. Watches only its own device, so a state
/// change elsewhere in the home does not rebuild it.
class DeviceTile extends ConsumerWidget {
  const DeviceTile({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceProvider(deviceId));
    if (device == null) return const SizedBox.shrink();
    return _DeviceCard(device: device);
  }
}

class _DeviceCard extends ConsumerStatefulWidget {
  const _DeviceCard({required this.device});

  final SmartHomeDevice device;

  @override
  ConsumerState<_DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends ConsumerState<_DeviceCard> {
  bool _busy = false;

  Future<void> _run(DeviceCommand command) async {
    setState(() => _busy = true);
    await runDeviceCommand(context, ref, widget.device, command);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final status = context.statusColors;
    final tone = DevicePresentation.tone(device);
    final toneColor = tone.color(
      theme.colorScheme,
      warning: status.warning,
      critical: status.critical,
      unavailable: status.unavailable,
    );
    final statusText = DevicePresentation.status(l10n, device);
    final highlighted =
        tone == DeviceTone.active || tone == DeviceTone.critical;

    final Widget? action = !device.available
        ? null
        : DevicePresentation.hasQuickToggle(device)
        ? Switch(
            value: device.state.isOn ?? false,
            onChanged: _busy
                ? null
                : (on) => _run(on ? const TurnOn() : const TurnOff()),
          )
        : DevicePresentation.hasQuickActivate(device)
        ? IconButton.filledTonal(
            tooltip: l10n.activate,
            onPressed: _busy ? null : () => _run(const Activate()),
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
          )
        : null;

    return Semantics(
      label: '${device.name}, $statusText',
      button: true,
      excludeSemantics: action == null,
      child: Card.outlined(
        clipBehavior: Clip.antiAlias,
        color: tone == DeviceTone.critical
            ? status.critical.withValues(alpha: 0.12)
            : highlighted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
            : null,
        child: InkWell(
          onTap: () => context.push(AppRoutes.device(device.id)),
          child: Opacity(
            opacity: device.available ? 1 : 0.6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        DevicePresentation.icon(device),
                        color: toneColor,
                        size: 28,
                      ),
                      const Spacer(),
                      if (device.hasLowBattery)
                        Tooltip(
                          message: l10n.lowBattery,
                          child: Icon(
                            Icons.battery_alert,
                            color: status.warning,
                            size: 20,
                          ),
                        ),
                      ?action,
                    ],
                  ),
                  const Spacer(),
                  Text(
                    device.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (!device.available) ...[
                        Icon(Icons.cloud_off, size: 14, color: toneColor),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tone == DeviceTone.neutral
                                ? null
                                : toneColor,
                            fontWeight: tone == DeviceTone.critical
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
