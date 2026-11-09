import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/session_controller.dart';
import '../../devices/application/device_providers.dart';

/// Something a camera (or a sensor of the same device) noticed.
@immutable
class CameraEvent {
  const CameraEvent({
    required this.when,
    required this.title,
    this.description,
    this.ai = false,
  });

  final DateTime when;
  final String title;

  /// What an AI (LLM Vision) saw, when it described the event.
  final String? description;
  final bool ai;
}

/// How far back the camera's timeline goes.
const cameraEventsSpan = Duration(hours: 24);

/// Events of the last day for [cameraId], newest first: motion, people and
/// doorbell rings from entities of the same HA device (logbook), and the
/// LLM Vision timeline when that integration is installed. Read only;
/// nothing leaves the home.
final cameraEventsProvider = FutureProvider.autoDispose
    .family<List<CameraEvent>, String>((ref, cameraId) async {
      final api = ref.watch(homeAssistantApiProvider);
      if (api == null) return const [];
      final devices = ref.read(homeSnapshotProvider).devices;
      final camera = devices[cameraId];
      if (camera == null) return const [];
      final end = DateTime.now();
      final start = end.subtract(cameraEventsSpan);
      final siblings = [
        if (camera.deviceId case final deviceId?)
          for (final d in devices.values)
            if (d.deviceId == deviceId &&
                d.id != cameraId &&
                (d.id.startsWith('binary_sensor.') ||
                    d.id.startsWith('event.')))
              d,
      ];
      final events = <CameraEvent>[];
      for (final sensor in siblings) {
        final entries = await api.fetchLogbook(sensor.id, start, end);
        for (final e in entries) {
          // A binary sensor is an event when it turns on; an `event.*`
          // entity's state is the time it fired.
          if (sensor.id.startsWith('binary_sensor.') && e.state != 'on') {
            continue;
          }
          if (e.state == 'unavailable' || e.state == 'unknown') continue;
          events.add(CameraEvent(when: e.when, title: e.name ?? sensor.name));
        }
      }
      // LLM Vision keeps its timeline as a calendar; each event names the
      // camera in its location.
      try {
        final calendars = await api.fetchCalendars();
        for (final c in calendars) {
          if (!c.entityId.contains('llm_vision')) continue;
          for (final e in await api.fetchCalendarEvents(
            c.entityId,
            start,
            end,
          )) {
            final where = e.location ?? '';
            if (where != cameraId && where != camera.name) continue;
            events.add(
              CameraEvent(
                when: e.start,
                title: e.summary,
                description: e.description,
                ai: true,
              ),
            );
          }
        }
      } on Object {
        // No calendars: only the sensors' events.
      }
      events.sort((a, b) => b.when.compareTo(a.when));
      return events.take(30).toList();
    });
