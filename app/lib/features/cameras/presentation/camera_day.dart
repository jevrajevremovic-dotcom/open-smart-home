import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/errors/app_failure.dart';
import '../../authentication/application/session_controller.dart';
import '../../devices/application/device_providers.dart';
import '../../restricted/application/restricted_mode.dart';
import '../application/camera_events.dart';
import '../application/camera_snapshots.dart';

/// One moment of the day: an event, its picture, or both.
typedef DayItem = ({
  DateTime when,
  String? title,
  String? description,
  bool ai,
  CameraSnapshot? picture,
});

/// Events with the picture taken right after each (within two minutes),
/// and pictures no event explains on their own; newest first.
List<DayItem> cameraDay(
  List<CameraEvent> events,
  List<CameraSnapshot> pictures,
) {
  final left = [...pictures];
  final out = <DayItem>[];
  for (final e in events) {
    CameraSnapshot? best;
    for (final p in left) {
      final d = p.when.difference(e.when);
      if (d < const Duration(seconds: -10) || d > const Duration(minutes: 2)) {
        continue;
      }
      if (best == null || d.abs() < best.when.difference(e.when).abs()) {
        best = p;
      }
    }
    if (best != null) left.remove(best);
    out.add((
      when: e.when,
      title: e.title,
      description: e.description,
      ai: e.ai,
      picture: best,
    ));
  }
  for (final p in left) {
    out.add((
      when: p.when,
      title: null,
      description: null,
      ai: false,
      picture: p,
    ));
  }
  out.sort((a, b) => b.when.compareTo(a.when));
  return out;
}

/// The last day at this camera: a 24-hour strip with a mark per moment,
/// then the moments as cards with their pictures. Pictures exist when the
/// user lets Home Assistant save one per event (the switch here).
class CameraDay extends ConsumerWidget {
  const CameraDay({super.key, required this.cameraId});

  final String cameraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final events = ref.watch(cameraEventsProvider(cameraId)).value ?? const [];
    final pictures =
        ref.watch(cameraSnapshotsProvider(cameraId)).value ?? const [];
    final camera = ref.watch(deviceProvider(cameraId));
    final sensors = camera == null
        ? const []
        : cameraSensors(camera, ref.watch(homeSnapshotProvider).devices.values);
    final restricted = ref.watch(
      restrictedModeProvider.select((r) => r.enabled),
    );
    final items = cameraDay(events, restricted ? const [] : pictures);
    if (items.isEmpty && (sensors.isEmpty || restricted)) {
      return const SizedBox.shrink();
    }
    final now = DateTime.now();
    final time = DateFormat.Hm(l10n.localeName);
    return Column(
      key: const Key('cameraEvents'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(l10n.cameraEvents, style: theme.textTheme.titleMedium),
        ),
        if (items.isNotEmpty) ...[
          _DayStrip(items: items, now: now),
          const SizedBox(height: 12),
          SizedBox(
            // Picture (200 × 9/16) plus two lines of text, as large as set.
            height: 113 + 2 * MediaQuery.textScalerOf(context).scale(18) + 16,
            child: ListView.separated(
              key: const Key('cameraDayList'),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _MomentCard(
                item: items[i],
                label: time.format(items[i].when),
              ),
            ),
          ),
        ],
        if (sensors.isNotEmpty && !restricted && camera != null)
          _SnapshotSwitch(cameraId: cameraId),
      ],
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.items, required this.now});

  final List<DayItem> items;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = now.subtract(const Duration(hours: 24));
    final hm = DateFormat.Hm(context.l10n.localeName);
    return Semantics(
      label: context.l10n.cameraDayStrip(items.length),
      child: Column(
        children: [
          SizedBox(
            height: 28,
            child: CustomPaint(
              size: Size.infinite,
              painter: _StripPainter(
                start: start,
                marks: [for (final i in items) (i.when, i.ai)],
                track: theme.colorScheme.surfaceContainerHighest,
                mark: theme.colorScheme.primary,
                aiMark: theme.colorScheme.tertiary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var h = 0; h <= 24; h += 12)
                Text(
                  hm.format(start.add(Duration(hours: h))),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StripPainter extends CustomPainter {
  _StripPainter({
    required this.start,
    required this.marks,
    required this.track,
    required this.mark,
    required this.aiMark,
  });

  final DateTime start;
  final List<(DateTime, bool)> marks;
  final Color track;
  final Color mark;
  final Color aiMark;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, mid - 4, size.width, 8),
        const Radius.circular(4),
      ),
      Paint()..color = track,
    );
    final paint = Paint();
    for (final (t, ai) in marks) {
      final f =
          t.difference(start).inSeconds / const Duration(hours: 24).inSeconds;
      if (f < 0 || f > 1) continue;
      paint.color = ai ? aiMark : mark;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(f * size.width, mid),
            width: 4,
            height: size.height,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripPainter old) =>
      old.marks != marks || old.start != start || old.mark != mark;
}

class _MomentCard extends ConsumerWidget {
  const _MomentCard({required this.item, required this.label});

  final DayItem item;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final picture = item.picture;
    final title = item.title ?? l10n.cameraSnapshotTaken;
    return SizedBox(
      width: 200,
      child: Card.outlined(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: picture == null
                    ? ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          item.ai
                              ? Icons.auto_awesome_outlined
                              : Icons.motion_photos_on,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : _Picture(id: picture.id),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                child: Text(
                  '$label · $title',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$label · ${item.title ?? context.l10n.cameraSnapshotTaken}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.picture case final p?)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _Picture(id: p.id, fit: BoxFit.contain),
                ),
              ),
            if (item.description case final d? when d.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(d),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.close),
        ),
      ],
    ),
  );
}

class _Picture extends ConsumerWidget {
  const _Picture({required this.id, this.fit = BoxFit.cover});

  final String id;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(snapshotImageProvider(id)).value;
    return ColoredBox(
      color: Colors.black,
      child: bytes == null
          ? const SizedBox.expand()
          : Image.memory(bytes, fit: fit, gaplessPlayback: true),
    );
  }
}

/// "Save a picture at every event" (an automation in Home Assistant).
class _SnapshotSwitch extends ConsumerStatefulWidget {
  const _SnapshotSwitch({required this.cameraId});

  final String cameraId;

  @override
  ConsumerState<_SnapshotSwitch> createState() => _SnapshotSwitchState();
}

class _SnapshotSwitchState extends ConsumerState<_SnapshotSwitch> {
  bool _busy = false;

  Future<void> _set(bool on) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(homeAssistantApiProvider);
    final camera = ref.read(deviceProvider(widget.cameraId));
    if (api == null || camera == null) return;
    setState(() => _busy = true);
    try {
      if (on) {
        await api.saveAutomation(
          snapshotAutomationId(camera.id),
          snapshotAutomationConfig(
            camera,
            cameraSensors(
              camera,
              ref.read(homeSnapshotProvider).devices.values,
            ),
            alias: l10n.cameraSnapshotAlias(camera.name),
          ),
        );
      } else {
        await api.deleteAutomation(snapshotAutomationId(camera.id));
      }
    } on AppFailure catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.kind == FailureKind.authorization
                  ? l10n.presenceNeedsAdmin
                  : l10n.autoSaveFailed,
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SwitchListTile(
      key: const Key('cameraSnapshotSwitch'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(l10n.cameraSnapshotSetting),
      subtitle: Text(l10n.cameraSnapshotHint),
      value: ref.watch(snapshotsOnProvider(widget.cameraId)),
      onChanged: _busy ? null : _set,
    );
  }
}
