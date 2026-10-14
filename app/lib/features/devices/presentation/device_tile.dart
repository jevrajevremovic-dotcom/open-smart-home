import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../kiosk/application/kiosk_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../application/device_providers.dart';
import '../data/home_state_repository.dart';
import '../domain/device_command.dart';
import '../domain/smart_home_device.dart';
import 'device_actions.dart';
import 'device_presentation.dart';

/// Compact card for one device. Watches only its own device, so a state
/// change elsewhere in the home does not rebuild it.
class DeviceTile extends ConsumerWidget {
  const DeviceTile({
    super.key,
    required this.deviceId,
    this.withoutRoomName = false,
  });

  final String deviceId;

  /// Inside a room's own screen the room name in front is redundant.
  final bool withoutRoomName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceProvider(deviceId));
    if (device == null) return const SizedBox.shrink();
    final roomName = withoutRoomName
        ? ref.watch(
            homeSnapshotProvider.select((s) => s.rooms[device.roomId]?.name),
          )
        : null;
    return _DeviceCard(
      device: device,
      name: DevicePresentation.shortName(device.name, roomName),
    );
  }
}

class _DeviceCard extends ConsumerStatefulWidget {
  const _DeviceCard({required this.device, required this.name});

  final SmartHomeDevice device;
  final String name;

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
    final scheme = theme.colorScheme;
    final status = context.statusColors;
    final accents = context.deviceAccents;
    final tone = DevicePresentation.tone(device);
    final statusText = DevicePresentation.status(l10n, device);

    // Active devices take their accent colour; alerts take warning/critical.
    final swatch = switch (tone) {
      DeviceTone.active => accents.of(DevicePresentation.accent(device)),
      DeviceTone.warning => accents.warning,
      DeviceTone.critical => accents.critical,
      _ => null,
    };
    final fill = swatch?.container ?? scheme.surfaceContainerLow;
    final onFill = swatch?.onContainer ?? scheme.onSurface;
    final onFillMuted = swatch?.onContainer ?? scheme.onSurfaceVariant;
    final iconColor =
        swatch?.icon ??
        (tone == DeviceTone.unavailable
            ? status.unavailable
            : scheme.onSurfaceVariant);
    final disc = swatch != null ? accents.iconDisc : scheme.surfaceContainer;

    final live = ref.watch(syncStatusProvider) == SyncStatus.live;
    final Widget? action = !device.available
        ? null
        : DevicePresentation.hasQuickToggle(device)
        ? Switch(
            value: device.state.isOn ?? false,
            activeTrackColor: swatch?.icon,
            onChanged: _busy || !live
                ? null
                : (on) => _run(on ? const TurnOn() : const TurnOff()),
          )
        : DevicePresentation.hasQuickActivate(device)
        ? IconButton.filledTonal(
            tooltip: l10n.activate,
            onPressed: _busy || !live ? null : () => _run(const Activate()),
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
          )
        : null;

    return Semantics(
      label: '${widget.name}, $statusText',
      button: true,
      excludeSemantics: action == null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(
              AppRoutes.device(device.id, kiosk: ref.read(kioskActiveProvider)),
            ),
            child: Opacity(
              opacity: device.available ? 1 : 0.6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: disc,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            DevicePresentation.icon(device),
                            color: iconColor,
                            size: 22,
                          ),
                        ),
                        const Spacer(),
                        if (device.hasLowBattery)
                          Tooltip(
                            message: l10n.lowBattery,
                            child: Icon(
                              Icons.battery_alert,
                              color: swatch == accents.warning
                                  ? onFill
                                  : status.warning,
                              size: 20,
                            ),
                          ),
                        ?action,
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: onFill,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (!device.available) ...[
                          Icon(Icons.cloud_off, size: 14, color: iconColor),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onFillMuted,
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
      ),
    );
  }
}
