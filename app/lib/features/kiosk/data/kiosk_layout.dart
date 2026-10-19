import 'dart:math';

import 'package:flutter/foundation.dart';

/// Kinds of panel the wall-panel layout can hold.
enum KioskPanelType {
  camera,
  weather,
  thermostat,
  rooms,
  shortcuts,
  scenes,
  calendar,
  device,

  /// A Home Assistant to-do / shopping list.
  lists,

  /// The family board (handwriting and drawings).
  board,

  /// The music player (a chosen player, or whatever plays now).
  media,

  /// Live power, today's energy and the current rate.
  energy;

  /// Needs a device chosen (the thermostat and lists pick one themselves
  /// when empty).
  bool get usesEntity =>
      this == thermostat || this == device || this == lists || this == media;
}

/// One panel: its place is its index in [KioskLayout.panels]; [span] is
/// its width in a 12-column grid, [height] 1 (normal) or 2 (tall).
@immutable
class KioskPanel {
  const KioskPanel({
    required this.id,
    required this.type,
    this.span = 4,
    this.height = 1,
    this.entityId,
  });

  static KioskPanel? tryParse(Object? json) {
    if (json is! Map) return null;
    final type = KioskPanelType.values
        .where((t) => t.name == json['type'])
        .firstOrNull;
    final id = json['id'];
    if (type == null || id is! String || id.isEmpty) return null;
    final span = json['span'];
    final height = json['height'];
    final entity = json['entityId'];
    return KioskPanel(
      id: id,
      type: type,
      span: span is int ? span.clamp(KioskLayout.minSpan, 12) : 4,
      height: height == 2 ? 2 : 1,
      entityId: entity is String ? entity : null,
    );
  }

  final String id;
  final KioskPanelType type;
  final int span;
  final int height;
  final String? entityId;

  KioskPanel copyWith({int? span, int? height, String? entityId}) => KioskPanel(
    id: id,
    type: type,
    span: span ?? this.span,
    height: height ?? this.height,
    entityId: entityId ?? this.entityId,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'span': span,
    'height': height,
    'entityId': ?entityId,
  };

  @override
  bool operator ==(Object other) =>
      other is KioskPanel &&
      other.id == id &&
      other.type == type &&
      other.span == span &&
      other.height == height &&
      other.entityId == entityId;

  @override
  int get hashCode => Object.hash(id, type, span, height, entityId);
}

@immutable
class KioskLayout {
  const KioskLayout(this.panels);

  static const minSpan = 3;
  static const maxPanels = 16;

  final List<KioskPanel> panels;

  /// The layout the kiosk had before it could be edited.
  /// Weather is in the header's numbers (a tap opens the forecast), so the
  /// rooms get the room instead.
  static const standard = KioskLayout([
    KioskPanel(id: 'camera', type: KioskPanelType.camera, span: 5),
    KioskPanel(id: 'thermostat', type: KioskPanelType.thermostat, span: 3),
    KioskPanel(id: 'calendar', type: KioskPanelType.calendar, span: 4),
    KioskPanel(id: 'rooms', type: KioskPanelType.rooms, span: 8),
    KioskPanel(id: 'shortcuts', type: KioskPanelType.shortcuts, span: 4),
  ]);

  /// `null` for missing or broken data: the standard layout is used then.
  static KioskLayout? tryParse(Object? json) {
    if (json is! List) return null;
    final seen = <String>{};
    final panels = [
      for (final p in json.map(KioskPanel.tryParse).nonNulls)
        if (seen.add(p.id)) p,
    ].take(maxPanels).toList();
    return panels.isEmpty ? null : KioskLayout(panels);
  }

  List<Map<String, Object?>> toJson() => [for (final p in panels) p.toJson()];

  /// Panels flowed into rows of at most 12 columns, in order.
  static List<List<KioskPanel>> rows(Iterable<KioskPanel> panels) {
    final rows = <List<KioskPanel>>[];
    var used = 12;
    for (final p in panels) {
      if (used + p.span > 12) {
        rows.add([]);
        used = 0;
      }
      rows.last.add(p);
      used += p.span;
    }
    return rows;
  }

  KioskLayout _with(List<KioskPanel> panels) => KioskLayout(panels);

  int _index(String id) => panels.indexWhere((p) => p.id == id);

  /// Moves [id] next to [targetId] (after it when [after]).
  KioskLayout move(String id, String targetId, {required bool after}) {
    if (id == targetId) return this;
    final list = [...panels];
    final from = list.indexWhere((p) => p.id == id);
    if (from < 0) return this;
    final panel = list.removeAt(from);
    final to = list.indexWhere((p) => p.id == targetId);
    if (to < 0) return this;
    list.insert(after ? to + 1 : to, panel);
    return _with(list);
  }

  KioskLayout update(String id, KioskPanel Function(KioskPanel) change) {
    final i = _index(id);
    if (i < 0) return this;
    return _with([...panels]..[i] = change(panels[i]));
  }

  KioskLayout resize(String id, int delta) =>
      update(id, (p) => p.copyWith(span: (p.span + delta).clamp(minSpan, 12)));

  KioskLayout toggleHeight(String id) =>
      update(id, (p) => p.copyWith(height: p.height == 1 ? 2 : 1));

  KioskLayout remove(String id) =>
      _with([...panels]..removeWhere((p) => p.id == id));

  KioskLayout add(KioskPanelType type, {String? entityId}) {
    if (panels.length >= maxPanels) return this;
    final r = Random();
    final id = '${type.name}-${r.nextInt(1 << 32).toRadixString(36)}';
    return _with([
      ...panels,
      KioskPanel(id: id, type: type, entityId: entityId),
    ]);
  }

  @override
  bool operator ==(Object other) =>
      other is KioskLayout && listEquals(other.panels, panels);

  @override
  int get hashCode => Object.hashAll(panels);
}

/// Templates for a new kiosk page.
enum KioskPageTemplate { empty, cameras, climateEnergy }

/// An extra kiosk page (swiped to from the home page), with its own name and
/// layout.
@immutable
class KioskPage {
  const KioskPage({
    required this.id,
    required this.name,
    required this.layout,
    this.from,
    this.to,
  });

  static const maxPages = 6;

  final String id;
  final String name;
  final KioskLayout layout;

  /// Shown by default between [from] and [to] (minutes after midnight, may
  /// cross midnight); `null` = only when swiped to.
  final int? from;
  final int? to;

  bool get scheduled => from != null && to != null && from != to;

  bool activeAt(DateTime now) {
    if (!scheduled) return false;
    final m = now.hour * 60 + now.minute;
    return from! < to! ? m >= from! && m < to! : m >= from! || m < to!;
  }

  static KioskPage? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String) return null;
    int? minutes(Object? v) => v is int && v >= 0 && v < 24 * 60 ? v : null;
    return KioskPage(
      id: id,
      name: name,
      layout: KioskLayout.tryParse(json['panels']) ?? const KioskLayout([]),
      from: minutes(json['from']),
      to: minutes(json['to']),
    );
  }

  /// A new page from [template], named [name].
  static KioskPage create(KioskPageTemplate template, String name) {
    final id = 'page-${Random().nextInt(1 << 32).toRadixString(36)}';
    KioskPanel panel(KioskPanelType type, int span, {int height = 1}) =>
        KioskPanel(
          id: '${type.name}-$id',
          type: type,
          span: span,
          height: height,
        );
    return KioskPage(
      id: id,
      name: name,
      layout: KioskLayout(switch (template) {
        KioskPageTemplate.empty => const [],
        KioskPageTemplate.cameras => [
          panel(KioskPanelType.camera, 12, height: 2),
        ],
        KioskPageTemplate.climateEnergy => [
          panel(KioskPanelType.thermostat, 5, height: 2),
          panel(KioskPanelType.energy, 7),
          panel(KioskPanelType.weather, 7),
        ],
      }),
    );
  }

  KioskPage copyWith({
    String? name,
    KioskLayout? layout,
    (int, int)? schedule,
    bool clearSchedule = false,
  }) => KioskPage(
    id: id,
    name: name ?? this.name,
    layout: layout ?? this.layout,
    from: clearSchedule ? null : (schedule?.$1 ?? from),
    to: clearSchedule ? null : (schedule?.$2 ?? to),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'panels': layout.toJson(),
    'from': ?from,
    'to': ?to,
  };

  @override
  bool operator ==(Object other) =>
      other is KioskPage &&
      other.id == id &&
      other.name == name &&
      other.layout == layout &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(id, name, layout, from, to);
}
