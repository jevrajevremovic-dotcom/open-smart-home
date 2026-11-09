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
}

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

  /// One per kind for the whole-home ones; per first sensor otherwise
  /// (a night light per hallway).
  String get id => switch (kind) {
    RecipeKind.leak ||
    RecipeKind.smoke ||
    RecipeKind.lastOut => '$recipePrefix${kind.name}',
    _ =>
      '$recipePrefix${kind.name}_'
          '${haSlug(sensors.isEmpty ? 'x' : sensors.first)}',
  };

  /// Enough chosen to work.
  bool get complete => switch (kind) {
    RecipeKind.lastOut => true,
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
  }) => Recipe(
    kind: kind,
    sensors: sensors ?? this.sensors,
    targets: targets ?? this.targets,
    minutes: minutes ?? this.minutes,
    onlyAtNight: onlyAtNight ?? this.onlyAtNight,
    phone: clearPhone ? null : phone ?? this.phone,
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

String recipeTitle(AppLocalizations l10n, RecipeKind k) => switch (k) {
  RecipeKind.leak => l10n.recipeLeak,
  RecipeKind.smoke => l10n.recipeSmoke,
  RecipeKind.followPresence => l10n.recipeFollow,
  RecipeKind.nightLight => l10n.recipeNightLight,
  RecipeKind.leftOpen => l10n.recipeLeftOpen,
  RecipeKind.lastOut => l10n.recipeLastOut,
};

String recipeHint(AppLocalizations l10n, RecipeKind k) => switch (k) {
  RecipeKind.leak => l10n.recipeLeakHint,
  RecipeKind.smoke => l10n.recipeSmokeHint,
  RecipeKind.followPresence => l10n.recipeFollowHint,
  RecipeKind.nightLight => l10n.recipeNightLightHint,
  RecipeKind.leftOpen => l10n.recipeLeftOpenHint,
  RecipeKind.lastOut => l10n.recipeLastOutHint,
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
