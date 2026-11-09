import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/l10n.dart';
import '../../core/utils/value_list.dart';
import '../devices/application/device_providers.dart';
import '../ha_notify/ha_push.dart' show haSlug;
import '../household/family_messages.dart';

/// Ready-made automations: chosen in a few taps, saved as ordinary Home
/// Assistant automations (they run with every phone off). Each keeps its
/// choices in its `variables`, so it can be edited from the app again.
enum RecipeKind {
  /// A leak sensor gets wet: the water valve closes, everyone is told.
  leak,

  /// Smoke or CO: every light on, everyone is told.
  smoke,

  /// Lights on while someone is in the room, off a while after.
  followPresence,

  /// Movement at night: a dim light for a couple of minutes.
  nightLight,

  /// A door or window open too long: a message.
  leftOpen,

  /// The last one out: lights off, a message.
  lastOut,

  /// A leak, smoke, CO or the alarm: the chosen phones with a "Got it"
  /// button; nobody answers in time, the others too, and again.
  escalation,
}

/// The button an escalation waits for (`mobile_app_notification_action`).
const escalationAck = 'OSH_ACK';

/// Tag of the escalation's notifications (cleared when answered).
const escalationTag = 'osh_alert';

/// Id prefix of every recipe automation.
const recipePrefix = 'osh_recipe_';

/// One recipe with its choices.
@immutable
class Recipe {
  const Recipe({
    required this.kind,
    this.sensors = const [],
    this.targets = const [],
    this.minutes = 5,
    this.onlyAtNight = false,
    this.phone,
    this.others = const [],
  });

  /// Back from the saved automation (its `variables`), or null.
  static Recipe? fromAutomation(Map<String, Object?> config) {
    final v = config['variables'];
    if (v is! Map) return null;
    final kind = RecipeKind.values
        .where((k) => k.name == v['osh_recipe'])
        .firstOrNull;
    if (kind == null) return null;
    List<String> list(Object? o) => [
      if (o is List)
        for (final x in o)
          if (x is String) x,
    ];
    return Recipe(
      kind: kind,
      sensors: list(v['osh_sensors']),
      targets: list(v['osh_targets']),
      minutes: (v['osh_minutes'] as num?)?.toInt() ?? 5,
      onlyAtNight: v['osh_night'] == true,
      phone: v['osh_phone'] as String?,
      others: list(v['osh_others']),
    );
  }

  final RecipeKind kind;

  /// What it watches (leak, smoke, motion, contact sensors).
  final List<String> sensors;

  /// What it acts on (valve, lights).
  final List<String> targets;
  final int minutes;
  final bool onlyAtNight;

  /// `notify.mobile_app_…` of this phone, to tell it too.
  final String? phone;

  /// Escalation: who is told when the first ones do not answer.
  final List<String> others;

  /// One per kind for the whole-home ones; per first sensor otherwise
  /// (a night light per hallway).
  String get id => switch (kind) {
    RecipeKind.leak ||
    RecipeKind.smoke ||
    RecipeKind.lastOut ||
    RecipeKind.escalation => '$recipePrefix${kind.name}',
    _ =>
      '$recipePrefix${kind.name}_'
          '${haSlug(sensors.isEmpty ? 'x' : sensors.first)}',
  };

  /// Enough chosen to work.
  bool get complete => switch (kind) {
    RecipeKind.lastOut => true,
    RecipeKind.escalation => sensors.isNotEmpty && targets.isNotEmpty,
    RecipeKind.followPresence ||
    RecipeKind.nightLight => sensors.isNotEmpty && targets.isNotEmpty,
    _ => sensors.isNotEmpty,
  };

  Recipe copyWith({
    List<String>? sensors,
    List<String>? targets,
    int? minutes,
    bool? onlyAtNight,
    String? phone,
    bool clearPhone = false,
    List<String>? others,
  }) => Recipe(
    kind: kind,
    sensors: sensors ?? this.sensors,
    targets: targets ?? this.targets,
    minutes: minutes ?? this.minutes,
    onlyAtNight: onlyAtNight ?? this.onlyAtNight,
    phone: clearPhone ? null : phone ?? this.phone,
    others: others ?? this.others,
  );

  /// A household message (the app and the wall panel show it) and, when
  /// chosen, this phone's notification.
  List<Map<String, Object?>> _tell(String title, String message) => [
    if (phone != null)
      {
        'action': phone,
        'continue_on_error': true,
        'data': {'title': title, 'message': message},
      },
    {
      'action': 'persistent_notification.create',
      'data': {
        'notification_id':
            '${FamilyMessage.prefix}${FamilyMessage.everyone}_'
            '{{ now().timestamp() | int }}',
        'title': title,
        'message': message,
      },
    },
  ];

  /// Closes a valve or switches off a switch, whichever it is.
  static Map<String, Object?> _shut(String id) => {
    'action': id.startsWith('valve.') ? 'valve.close_valve' : 'switch.turn_off',
    'continue_on_error': true,
    'target': {'entity_id': id},
  };

  static const _night = {
    'condition': 'state',
    'entity_id': 'sun.sun',
    'state': 'below_horizon',
  };

  /// The Home Assistant automation: documented triggers (`state`,
  /// `numeric_state`), conditions and actions only.
  Map<String, Object?> automation(AppLocalizations l10n) {
    final title = recipeTitle(l10n, kind);
    final config = <String, Object?>{
      'alias': '$title (Open Smart Home)',
      'description': 'Open Smart Home',
      'variables': {
        'osh_recipe': kind.name,
        'osh_sensors': sensors,
        'osh_targets': targets,
        'osh_minutes': minutes,
        'osh_night': onlyAtNight,
        'osh_phone': ?phone,
        'osh_others': others,
      },
    };
    switch (kind) {
      case RecipeKind.leak:
        return {
          ...config,
          'mode': 'single',
          'triggers': [
            {'trigger': 'state', 'entity_id': sensors, 'to': 'on'},
          ],
          'conditions': <Object>[],
          'actions': [
            for (final t in targets) _shut(t),
            ..._tell(
              title,
              targets.isEmpty
                  ? l10n.recipeLeakMessage('{{ trigger.to_state.name }}')
                  : l10n.recipeLeakClosedMessage('{{ trigger.to_state.name }}'),
            ),
          ],
        };
      case RecipeKind.smoke:
        return {
          ...config,
          'mode': 'single',
          'triggers': [
            {'trigger': 'state', 'entity_id': sensors, 'to': 'on'},
          ],
          'conditions': <Object>[],
          'actions': [
            // So nobody looks for the way out in the dark.
            {
              'action': 'light.turn_on',
              'continue_on_error': true,
              'target': {'entity_id': 'all'},
              'data': {'brightness_pct': 100},
            },
            ..._tell(
              title,
              l10n.recipeSmokeMessage('{{ trigger.to_state.name }}'),
            ),
          ],
        };
      case RecipeKind.followPresence:
        return {
          ...config,
          'mode': 'restart',
          'triggers': [
            {'trigger': 'state', 'entity_id': sensors, 'to': 'on', 'id': 'on'},
            {
              'trigger': 'state',
              'entity_id': sensors,
              'to': 'off',
              'for': {'minutes': minutes},
              'id': 'off',
            },
          ],
          'conditions': <Object>[],
          'actions': [
            {
              'choose': [
                {
                  'conditions': [
                    {'condition': 'trigger', 'id': 'on'},
                    if (onlyAtNight) _night,
                  ],
                  'sequence': [
                    {
                      'action': 'light.turn_on',
                      'target': {'entity_id': targets},
                    },
                  ],
                },
                {
                  'conditions': [
                    {'condition': 'trigger', 'id': 'off'},
                  ],
                  'sequence': [
                    {
                      'action': 'light.turn_off',
                      'target': {'entity_id': targets},
                    },
                  ],
                },
              ],
            },
          ],
        };
      case RecipeKind.nightLight:
        return {
          ...config,
          'mode': 'restart',
          'triggers': [
            {'trigger': 'state', 'entity_id': sensors, 'to': 'on'},
          ],
          'conditions': [_night],
          'actions': [
            {
              'action': 'light.turn_on',
              'target': {'entity_id': targets},
              'data': {'brightness_pct': 20},
            },
            {
              'delay': {'minutes': minutes},
            },
            {
              'action': 'light.turn_off',
              'target': {'entity_id': targets},
            },
          ],
        };
      case RecipeKind.leftOpen:
        return {
          ...config,
          'mode': 'parallel',
          'triggers': [
            {
              'trigger': 'state',
              'entity_id': sensors,
              'to': 'on',
              'for': {'minutes': minutes},
            },
          ],
          'conditions': <Object>[],
          'actions': _tell(
            title,
            l10n.recipeLeftOpenMessage('{{ trigger.to_state.name }}', minutes),
          ),
        };
      case RecipeKind.escalation:
        return {...config, ..._escalation(l10n, title)};
      case RecipeKind.lastOut:
        return {
          ...config,
          'mode': 'single',
          // `zone.home` counts the people at home.
          'triggers': [
            {'trigger': 'numeric_state', 'entity_id': 'zone.home', 'below': 1},
          ],
          'conditions': <Object>[],
          'actions': [
            {
              'action': 'light.turn_off',
              'continue_on_error': true,
              'target': {'entity_id': 'all'},
            },
            ..._tell(title, l10n.recipeLastOutMessage),
          ],
        };
    }
  }
}

extension on Recipe {
  /// Tells [phones] with a "Got it" button, under one tag.
  List<Map<String, Object?>> _ask(
    List<String> phones,
    String title,
    String message,
    String ack,
  ) => [
    for (final p in phones)
      {
        'action': p,
        'continue_on_error': true,
        'data': {
          'title': title,
          'message': message,
          'data': {
            'tag': escalationTag,
            'entity_id': '{{ trigger.entity_id }}',
            'actions': [
              {'action': escalationAck, 'title': ack},
            ],
          },
        },
      },
  ];

  /// The answer (from any phone), or nothing for [minutes].
  Map<String, Object?> _wait() => {
    'wait_for_trigger': [
      {
        'trigger': 'event',
        'event_type': 'mobile_app_notification_action',
        'event_data': {'action': escalationAck},
      },
    ],
    'timeout': {'minutes': minutes},
    'continue_on_timeout': true,
  };

  /// Answered: the question goes away on every phone, and the household
  /// sees that it was taken care of.
  List<Map<String, Object?>> _answered(String done) => [
    for (final p in {...targets, ...others})
      {
        'action': p,
        'continue_on_error': true,
        'data': {
          'message': 'clear_notification',
          'data': {'tag': escalationTag},
        },
      },
    {
      'action': 'persistent_notification.create',
      'data': {
        'notification_id':
            '${FamilyMessage.prefix}${FamilyMessage.everyone}_'
            '{{ now().timestamp() | int }}',
        'message': done,
      },
    },
  ];

  /// Documented script features only: `wait_for_trigger` on the event the
  /// apps fire for a pressed button, `if`/`then`/`else`, `wait.trigger`.
  Map<String, Object?> _escalation(AppLocalizations l10n, String title) {
    const what = '{{ trigger.to_state.name }}';
    const noAnswer = {
      'condition': 'template',
      'value_template': '{{ wait.trigger is none }}',
    };
    final ack = l10n.escalationAck;
    final everyone = [
      ...{...targets, ...others},
    ];
    return {
      'mode': 'single',
      'triggers': [
        for (final id in sensors)
          {
            'trigger': 'state',
            'entity_id': id,
            'to': id.startsWith('alarm_control_panel.') ? 'triggered' : 'on',
          },
      ],
      'conditions': <Object>[],
      'actions': [
        ..._ask(targets, title, l10n.escalationFirst(what), ack),
        {
          'action': 'persistent_notification.create',
          'data': {
            'notification_id':
                '${FamilyMessage.prefix}${FamilyMessage.everyone}_'
                '{{ now().timestamp() | int }}',
            'title': title,
            'message': l10n.escalationFirst(what),
          },
        },
        _wait(),
        {
          'if': [noAnswer],
          'then': [
            ..._ask(everyone, title, l10n.escalationSecond(what), ack),
            _wait(),
            {
              'if': [noAnswer],
              'then': _ask(everyone, title, l10n.escalationThird(what), ack),
              'else': _answered(l10n.escalationDone(what)),
            },
          ],
          'else': _answered(l10n.escalationDone(what)),
        },
      ],
    };
  }
}

String recipeTitle(AppLocalizations l10n, RecipeKind k) => switch (k) {
  RecipeKind.leak => l10n.recipeLeak,
  RecipeKind.smoke => l10n.recipeSmoke,
  RecipeKind.followPresence => l10n.recipeFollow,
  RecipeKind.nightLight => l10n.recipeNightLight,
  RecipeKind.leftOpen => l10n.recipeLeftOpen,
  RecipeKind.lastOut => l10n.recipeLastOut,
  RecipeKind.escalation => l10n.recipeEscalation,
};

String recipeHint(AppLocalizations l10n, RecipeKind k) => switch (k) {
  RecipeKind.leak => l10n.recipeLeakHint,
  RecipeKind.smoke => l10n.recipeSmokeHint,
  RecipeKind.followPresence => l10n.recipeFollowHint,
  RecipeKind.nightLight => l10n.recipeNightLightHint,
  RecipeKind.leftOpen => l10n.recipeLeftOpenHint,
  RecipeKind.lastOut => l10n.recipeLastOutHint,
  RecipeKind.escalation => l10n.recipeEscalationHint,
};

/// Recipe automations in the home, by id (their entities carry the id).
final savedRecipeIdsProvider = Provider<ValueList<String>>(
  (ref) => ref.watch(
    homeSnapshotProvider.select(
      (s) => ValueList(
        [
          for (final d in s.devices.values)
            if (d.metadata.configId case final id?
                when id.startsWith(recipePrefix))
              id,
        ]..sort(),
      ),
    ),
  ),
);
