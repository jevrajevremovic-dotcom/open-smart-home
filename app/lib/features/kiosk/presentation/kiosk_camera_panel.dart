import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../cameras/application/camera_providers.dart';
import '../../cameras/presentation/camera_view.dart';
import '../../devices/application/device_providers.dart';
import '../application/kiosk_controller.dart';
import 'glass.dart';

/// One camera at a time with buttons to switch, like a security monitor.
/// Tapping the picture opens the camera. Refreshing pauses while the
/// screensaver is on.
class KioskCameraPanel extends ConsumerStatefulWidget {
  const KioskCameraPanel({super.key});

  @override
  ConsumerState<KioskCameraPanel> createState() => _KioskCameraPanelState();
}

class _KioskCameraPanelState extends ConsumerState<KioskCameraPanel> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ids = ref.watch(cameraIdsProvider);
    if (ids.isEmpty) return const SizedBox.shrink();
    final selected = ids.contains(_selected) ? _selected! : ids.first;
    final dimmed = ref.watch(kioskDimmedProvider);

    final picture = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: dimmed
          ? const ColoredBox(color: Colors.black)
          : GestureDetector(
              onTap: () =>
                  context.push(AppRoutes.device(selected, kiosk: true)),
              child: CameraPicture(
                key: ValueKey('kioskCamera-$selected'),
                cameraId: selected,
              ),
            ),
    );

    return GlassPanel(
      key: const Key('kioskCameras'),
      padding: const EdgeInsets.all(14),
      child: Semantics(
        container: true,
        label: l10n.camerasTitle,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: picture),
            if (ids.length > 1) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 132,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final id in ids)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CameraTab(
                          cameraId: id,
                          selected: id == selected,
                          onTap: () => setState(() => _selected = id),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CameraTab extends ConsumerWidget {
  const _CameraTab({
    required this.cameraId,
    required this.selected,
    required this.onTap,
  });

  final String cameraId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name =
        ref.watch(deviceProvider(cameraId).select((d) => d?.name)) ?? cameraId;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: Material(
        color: selected ? GlassColors.fillStrong : GlassColors.fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? Colors.white70 : Colors.transparent,
          ),
        ),
        child: InkWell(
          key: ValueKey('cameraTab-$cameraId'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: selected ? GlassColors.text : GlassColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
