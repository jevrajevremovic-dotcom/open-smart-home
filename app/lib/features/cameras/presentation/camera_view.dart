import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/domain/smart_home_device.dart';
import '../application/camera_providers.dart';

/// Live-ish camera picture (refreshed snapshots) with a small time label.
/// Watching this widget is what keeps the camera refreshing.
class CameraPicture extends ConsumerWidget {
  const CameraPicture({
    super.key,
    required this.cameraId,
    this.fit = BoxFit.cover,
    this.showTime = true,
  });

  final String cameraId;
  final BoxFit fit;
  final bool showTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final frame = ref.watch(cameraFeedProvider(cameraId));
    final name = ref.watch(deviceProvider(cameraId).select((d) => d?.name));
    final bytes = frame.bytes;
    return Semantics(
      image: true,
      label: [?name, if (frame.failing) l10n.cameraUnavailable].join(', '),
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes != null)
              Image.memory(
                bytes,
                key: const Key('cameraImage'),
                fit: fit,
                gaplessPlayback: true, // no flicker between snapshots
                excludeFromSemantics: true,
              )
            else if (!frame.failing)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white70),
                    const SizedBox(height: 12),
                    Text(
                      l10n.cameraLoading,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            if (frame.failing)
              Align(
                alignment: bytes == null ? Alignment.center : Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _Badge(
                    key: const Key('cameraUnavailable'),
                    icon: Icons.videocam_off_outlined,
                    text: l10n.cameraUnavailable,
                  ),
                ),
              ),
            if (showTime && frame.takenAt != null)
              Positioned(
                left: 10,
                bottom: 10,
                child: _Badge(
                  icon: Icons.fiber_manual_record,
                  iconColor: frame.failing
                      ? Colors.white54
                      : const Color(0xFFFF5A5F),
                  text: DateFormat.Hms(l10n.localeName).format(frame.takenAt!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String text;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Camera section of the device screen.
class CameraDetail extends StatelessWidget {
  const CameraDetail({super.key, required this.device});

  final SmartHomeDevice device;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: GestureDetector(
              onTap: () => openCameraFullscreen(context, device.id),
              child: CameraPicture(cameraId: device.id),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.cameraRefreshHint(cameraRefreshInterval.inSeconds),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              key: const Key('cameraFullscreen'),
              onPressed: () => openCameraFullscreen(context, device.id),
              icon: const Icon(Icons.fullscreen),
              label: Text(l10n.cameraFullscreen),
            ),
          ],
        ),
      ],
    );
  }
}

/// Black full-screen view with pinch-to-zoom. Pushed on the nearest
/// navigator, so the kiosk's "return to dashboard" also closes it.
Future<void> openCameraFullscreen(BuildContext context, String cameraId) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          key: const Key('cameraFullscreenView'),
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Consumer(
              builder: (context, ref, _) => Text(
                ref.watch(deviceProvider(cameraId).select((d) => d?.name)) ??
                    '',
              ),
            ),
          ),
          body: InteractiveViewer(
            maxScale: 5,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CameraPicture(cameraId: cameraId, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
