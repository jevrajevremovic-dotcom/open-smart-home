import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/session_controller.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/domain/smart_home_device.dart';

/// Pictures Home Assistant takes when a camera's sensors notice something
/// (`camera.snapshot`, into its own media folder), for the day's timeline.
/// They stay on the server; the app removes them after [keepSnapshots].
const keepSnapshots = Duration(days: 7);

String _slug(String cameraId) => cameraId.split('.').last;

/// Folder under HA's `/media` (the "local" media source).
String snapshotFolder(String cameraId) => 'open_smart_home/${_slug(cameraId)}';

String snapshotFolderId(String cameraId) =>
    'media-source://media_source/local/${snapshotFolder(cameraId)}';

String snapshotAutomationId(String cameraId) {
  final id = 'osh_snap_${_slug(cameraId)}';
  return id.length <= 64 ? id : id.substring(0, 64);
}

/// Sensors of the camera's own HA device that make a good "something
/// happened": motion, a person, the doorbell.
List<SmartHomeDevice> cameraSensors(
  SmartHomeDevice camera,
  Iterable<SmartHomeDevice> devices,
) => [
  if (camera.deviceId case final deviceId?)
    for (final d in devices)
      if (d.deviceId == deviceId &&
          d.id != camera.id &&
          (d.id.startsWith('binary_sensor.') || d.id.startsWith('event.')))
        d,
];

/// One picture per event, at most every 30 seconds.
Map<String, Object?> snapshotAutomationConfig(
  SmartHomeDevice camera,
  List<SmartHomeDevice> sensors, {
  required String alias,
}) => {
  'id': snapshotAutomationId(camera.id),
  'alias': alias,
  'description': 'Open Smart Home',
  'mode': 'single',
  'max_exceeded': 'silent',
  'triggers': [
    for (final s in sensors)
      if (s.id.startsWith('event.'))
        {'trigger': 'state', 'entity_id': s.id}
      else
        {'trigger': 'state', 'entity_id': s.id, 'to': 'on'},
  ],
  'conditions': [],
  'actions': [
    {
      'action': 'camera.snapshot',
      'target': {'entity_id': camera.id},
      'data': {
        'filename':
            '/media/${snapshotFolder(camera.id)}/'
            "{{ now().strftime('%Y%m%d-%H%M%S') }}.jpg",
      },
    },
    {
      'delay': {'seconds': 30},
    },
  ],
};

@immutable
class CameraSnapshot {
  const CameraSnapshot(this.id, this.when);

  /// Media source id, to resolve the picture.
  final String id;
  final DateTime when;
}

/// `20261109-213005.jpg` → that local time.
DateTime? snapshotTime(String name) {
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})\.jpg$')
      .firstMatch(name);
  if (m == null) return null;
  final v = [for (var i = 1; i <= 6; i++) int.parse(m[i]!)];
  return DateTime(v[0], v[1], v[2], v[3], v[4], v[5]);
}

/// Whether HA saves pictures for this camera (its automation exists).
final snapshotsOnProvider = Provider.autoDispose.family<bool, String>(
  (ref, cameraId) => ref.watch(
    homeSnapshotProvider.select(
      (s) => s.devices.values.any(
        (d) => d.metadata.configId == snapshotAutomationId(cameraId),
      ),
    ),
  ),
);

/// The pictures of the last day, newest first. Older than [keepSnapshots]
/// are removed on the way (HA's `media_source/local_source/remove`,
/// administrators; quietly skipped otherwise).
final cameraSnapshotsProvider = FutureProvider.autoDispose
    .family<List<CameraSnapshot>, String>((ref, cameraId) async {
      final ws = ref.watch(webSocketManagerProvider);
      if (ws == null || !ref.watch(snapshotsOnProvider(cameraId))) {
        return const [];
      }
      final Object? folder;
      try {
        folder = await ws.sendCommand({
          'type': 'media_source/browse_media',
          'media_content_id': snapshotFolderId(cameraId),
        });
      } on Object {
        return const []; // no pictures yet: HA makes the folder with the first
      }
      final now = DateTime.now();
      final all = [
        if (folder case {'children': final List<Object?> children})
          for (final c in children)
            if (c case {
              'title': final String title,
              'media_content_id': final String id,
            })
              if (snapshotTime(title) case final at?) CameraSnapshot(id, at),
      ];
      for (final old in all.where(
        (s) => now.difference(s.when) > keepSnapshots,
      )) {
        try {
          await ws.sendCommand({
            'type': 'media_source/local_source/remove',
            'media_content_id': old.id,
          });
        } on Object {
          break; // not an administrator: leave them
        }
      }
      return [
        for (final s in all)
          if (now.difference(s.when) <= const Duration(hours: 24)) s,
      ]..sort((a, b) => b.when.compareTo(a.when));
    });

/// A picture's bytes: resolved to a short-lived signed path on the HA
/// server, then fetched from there (never another host).
final snapshotImageProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, mediaId) async {
      final ws = ref.watch(webSocketManagerProvider);
      final api = ref.watch(homeAssistantApiProvider);
      if (ws == null || api == null) throw StateError('not connected');
      final result = await ws.sendCommand({
        'type': 'media_source/resolve_media',
        'media_content_id': mediaId,
      });
      final url = result is Map ? result['url'] : null;
      if (url is! String) throw StateError('unexpected answer');
      return api.fetchImage(url);
    });
