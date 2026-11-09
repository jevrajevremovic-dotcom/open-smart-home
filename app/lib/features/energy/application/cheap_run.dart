import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/session_controller.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/domain/capability.dart';
import '../../devices/domain/device_kind.dart';
import '../../devices/domain/smart_home_device.dart';

/// "Run it when electricity is cheapest": the boiler, a plug with the
/// dishwasher on it… Home Assistant switches the device on at the start
/// of the window and off at the end, then turns its own automation off,
/// so it works with this phone off and runs only once.
String cheapRunId(String entityId) {
  final id = 'osh_cheap_${entityId.replaceAll('.', '_')}';
  return id.length <= 64 ? id : id.substring(0, 64);
}

/// Plain on/off devices: what can safely be switched on for a while.
bool supportsCheapRun(SmartHomeDevice d) =>
    !d.isAuxiliary &&
    d.supports(Capability.power) &&
    (d.kind == DeviceKind.switchDevice || d.kind == DeviceKind.outlet);

String _date(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

String _clock(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}:00';

/// The automation; [startNow] when the window has already begun (the app
/// switches the device on itself, HA only switches it off).
Map<String, Object?> cheapRunConfig(
  SmartHomeDevice d,
  DateTime start,
  DateTime end, {
  required String alias,
  bool startNow = false,
}) {
  // A time trigger fires every day: the date makes it this once.
  Map<String, Object?> on(DateTime t) => {
    'condition': 'template',
    'value_template': "{{ now().date() | string == '${_date(t)}' }}",
  };
  return {
    'id': cheapRunId(d.sourceId),
    'alias': alias,
    'description': 'Open Smart Home',
    'mode': 'single',
    'variables': {
      'osh_start': start.toIso8601String(),
      'osh_end': end.toIso8601String(),
    },
    'triggers': [
      if (!startNow) {'trigger': 'time', 'at': _clock(start), 'id': 'start'},
      {'trigger': 'time', 'at': _clock(end), 'id': 'end'},
    ],
    'conditions': [],
    'actions': [
      {
        'choose': [
          if (!startNow)
            {
              'conditions': [
                {'condition': 'trigger', 'id': 'start'},
                on(start),
              ],
              'sequence': [
                {
                  'action': 'homeassistant.turn_on',
                  'target': {'entity_id': d.sourceId},
                },
              ],
            },
          {
            'conditions': [
              {'condition': 'trigger', 'id': 'end'},
              on(end),
            ],
            'sequence': [
              {
                'action': 'homeassistant.turn_off',
                'target': {'entity_id': d.sourceId},
              },
              // Done: the automation turns itself off.
              {
                'action': 'automation.turn_off',
                'target': {'entity_id': '{{ this.entity_id }}'},
              },
            ],
          },
        ],
      },
    ],
  };
}

/// A planned run read back from Home Assistant.
@immutable
class CheapRun {
  const CheapRun(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

/// The device's planned run, if its automation exists, is on and has not
/// ended yet.
final cheapRunProvider = FutureProvider.autoDispose.family<CheapRun?, String>((
  ref,
  entityId,
) async {
  final id = cheapRunId(entityId);
  // Only whether it exists and is on: not every state change of the home.
  final on = ref.watch(
    homeSnapshotProvider.select(
      (s) => s.devices.values
          .where((d) => d.metadata.configId == id)
          .firstOrNull
          ?.state
          .isOn,
    ),
  );
  final api = ref.watch(homeAssistantApiProvider);
  if (on != true || api == null) return null;
  final config = await api.fetchAutomation(id);
  final variables = config['variables'];
  if (variables is! Map) return null;
  final start = DateTime.tryParse('${variables['osh_start']}');
  final end = DateTime.tryParse('${variables['osh_end']}');
  if (start == null || end == null || !end.isAfter(DateTime.now())) {
    return null;
  }
  return CheapRun(start, end);
});
