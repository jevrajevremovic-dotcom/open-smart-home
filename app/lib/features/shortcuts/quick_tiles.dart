import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../core/storage/app_preferences.dart';
import '../authentication/application/session_controller.dart';
import '../clap/clap_listener.dart';
import '../devices/application/device_command_service.dart';
import '../devices/application/device_providers.dart';
import '../devices/data/home_state_repository.dart';
import '../devices/domain/device_command.dart';
import '../devices/domain/device_kind.dart';
import '../devices/domain/smart_home_device.dart';

/// What a Quick Settings tile shows.
@immutable
class QuickTileState {
  const QuickTileState({required this.label, this.active});

  final String label;

  /// `null` for scenes (nothing stays on).
  final bool? active;

  Map<String, Object?> toJson() => {'label': label, 'active': active};

  @override
  bool operator ==(Object other) =>
      other is QuickTileState && other.label == label && other.active == active;

  @override
  int get hashCode => Object.hash(label, active);
}

abstract interface class QuickTilesPlatform {
  bool get supported;

  /// Labels and on/off of the three tiles (`null` = not set up).
  Future<void> update(List<QuickTileState?> tiles);

  /// The same for the car's buttons (Android Auto); their taps come back
  /// as [carIndexBase] + index.
  Future<void> updateCar(List<QuickTileState?> buttons);

  /// Taps queued while the app was not listening (or just now).
  Future<List<int>> takePending();

  /// A tile was tapped: call [takePending].
  Stream<void> get clicks;

  /// Android 13+: asks the system to add tile [index]; `false` when the
  /// user has to add it by hand.
  Future<bool> requestAdd(int index, String label);
}

class AndroidQuickTiles implements QuickTilesPlatform {
  AndroidQuickTiles() {
    if (supported) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'clicked') _clicks.add(null);
      });
    }
  }

  static const _channel = MethodChannel('org.opensmarthome/tiles');
  final _clicks = StreamController<void>.broadcast();

  @override
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> update(List<QuickTileState?> tiles) =>
      _channel.invokeMethod('update', {
        'tiles': jsonEncode([for (final t in tiles) t?.toJson()]),
      });

  @override
  Future<void> updateCar(List<QuickTileState?> buttons) =>
      _channel.invokeMethod('updateCar', {
        'buttons': jsonEncode([for (final t in buttons) t?.toJson()]),
      });

  @override
  Future<List<int>> takePending() async {
    final json = await _channel.invokeMethod<String>('takePending');
    final list = json == null ? null : jsonDecode(json);
    return [
      if (list is List)
        for (final i in list)
          if (i is int) i,
    ];
  }

  @override
  Stream<void> get clicks => _clicks.stream;

  @override
  Future<bool> requestAdd(int index, String label) async =>
      await _channel.invokeMethod<bool>('requestAdd', {
        'index': index,
        'label': label,
      }) ??
      false;
}

final quickTilesPlatformProvider = Provider<QuickTilesPlatform>(
  (ref) => AndroidQuickTiles(),
);

const quickTileCount = 3;

/// What a tile may do: switch a device or run a scene/script. Nothing that
/// opens a door, a garage or the alarm (a tap in a menu is no
/// confirmation).
DeviceCommand? quickTileCommand(SmartHomeDevice d) {
  if (const {
    DeviceKind.lock,
    DeviceKind.garageDoor,
    DeviceKind.alarm,
  }.contains(d.kind)) {
    return null;
  }
  final command = clapCommandFor(d);
  if (command == null || command.isCritical(d)) return null;
  return command;
}

/// Buttons on the car screen (Android Auto).
const carButtonCount = 6;

/// Taps on car buttons arrive as this + index (tiles: 0, 1, 2).
const carIndexBase = 100;

/// What a car button may do: what a tile may, and also open or close the
/// garage door or the gate and lock a lock — the reason to have it in the
/// car. Never unlock or disarm.
DeviceCommand? carCommand(SmartHomeDevice d) {
  if (d.kind == DeviceKind.garageDoor) {
    final command = clapCommandFor(d);
    return command is OpenCover || command is CloseCover ? command : null;
  }
  if (d.kind == DeviceKind.lock) {
    final command = clapCommandFor(d);
    return command is LockDevice ? command : null;
  }
  return quickTileCommand(d);
}

/// The device of each tile (or car button), per home.
class QuickTilesController extends Notifier<List<String?>> {
  QuickTilesController([this._prefix = 'quickTiles', this._count = 3]);

  final String _prefix;
  final int _count;

  String? get _key {
    final p = ref.read(activeProfileProvider);
    return p == null ? null : '$_prefix::${p.id}';
  }

  @override
  List<String?> build() {
    final p = ref.watch(activeProfileProvider);
    if (p == null) return List.filled(_count, null);
    final json = ref
        .watch(appPreferencesProvider)
        .readJson('$_prefix::${p.id}');
    final ids = json?['ids'];
    return [
      for (var i = 0; i < _count; i++)
        ids is List && i < ids.length && ids[i] is String
            ? ids[i] as String
            : null,
    ];
  }

  Future<void> set(int index, String? deviceId) async {
    final next = [...state]..[index] = deviceId;
    state = next;
    final key = _key;
    if (key != null) {
      await ref.read(appPreferencesProvider).writeJson(key, {'ids': next});
    }
  }
}

final quickTilesProvider =
    NotifierProvider<QuickTilesController, List<String?>>(
      QuickTilesController.new,
    );

final carButtonsProvider =
    NotifierProvider<QuickTilesController, List<String?>>(
      () => QuickTilesController('carButtons', carButtonCount),
    );

/// The tiles as the menu shows them, from live device state.
final quickTileStatesProvider = Provider<List<QuickTileState?>>(
  (ref) => _states(ref, ref.watch(quickTilesProvider)),
);

/// The car's buttons, the same way.
final carButtonStatesProvider = Provider<List<QuickTileState?>>(
  (ref) => _states(ref, ref.watch(carButtonsProvider)),
);

List<QuickTileState?> _states(Ref ref, List<String?> ids) {
  return [
    for (final id in ids)
      if (id == null)
        null
      else if (ref.watch(deviceProvider(id)) case final d?)
        QuickTileState(
          label: d.name,
          active: d.kind.isRoutine ? null : d.state.isOn ?? d.state.isActive,
        )
      else
        null,
  ];
}

/// Keeps the tiles current and runs their taps once Home Assistant is live
/// (the app may just have been started in the background by the tap).
class QuickTilesHost extends ConsumerStatefulWidget {
  const QuickTilesHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<QuickTilesHost> createState() => _QuickTilesHostState();
}

class _QuickTilesHostState extends ConsumerState<QuickTilesHost> {
  static final _log = AppLogger('QuickTiles');
  StreamSubscription<void>? _sub;
  final List<int> _queue = [];
  List<QuickTileState?>? _sent;
  List<QuickTileState?>? _sentCar;

  @override
  void initState() {
    super.initState();
    final platform = ref.read(quickTilesPlatformProvider);
    if (!platform.supported) return;
    _sub = platform.clicks.listen((_) => unawaited(_takePending()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_takePending());
      _push();
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  void _push() {
    final platform = ref.read(quickTilesPlatformProvider);
    if (!platform.supported) return;
    final tiles = ref.read(quickTileStatesProvider);
    if (_sent == null || !listEquals(_sent, tiles)) {
      _sent = tiles;
      unawaited(
        platform.update(tiles).catchError((Object e) {
          _log.info('tiles not updated: ${e.runtimeType}');
        }),
      );
    }
    final car = ref.read(carButtonStatesProvider);
    if (_sentCar == null || !listEquals(_sentCar, car)) {
      _sentCar = car;
      unawaited(
        platform.updateCar(car).catchError((Object e) {
          _log.info('car buttons not updated: ${e.runtimeType}');
        }),
      );
    }
  }

  Future<void> _takePending() async {
    try {
      _queue.addAll(await ref.read(quickTilesPlatformProvider).takePending());
    } on Object catch (e) {
      _log.info('no pending taps: ${e.runtimeType}');
    }
    await _run();
  }

  /// Runs queued taps when the home is live; otherwise they wait.
  Future<void> _run() async {
    if (_queue.isEmpty || !mounted) return;
    if (ref.read(syncStatusProvider) != SyncStatus.live) return;
    final service = ref.read(deviceCommandServiceProvider);
    final ids = ref.read(quickTilesProvider);
    final carIds = ref.read(carButtonsProvider);
    while (_queue.isNotEmpty && service != null) {
      final tap = _queue.removeAt(0);
      final car = tap >= carIndexBase;
      final index = car ? tap - carIndexBase : tap;
      final list = car ? carIds : ids;
      final id = index >= 0 && index < list.length ? list[index] : null;
      final device = id == null ? null : ref.read(deviceProvider(id));
      final command = device == null
          ? null
          : car
          ? carCommand(device)
          : quickTileCommand(device);
      if (device == null || command == null) continue;
      try {
        // A car button was set up for exactly this (the garage, the
        // gate) and pressed on the car's own screen: that is the
        // confirmation. Tiles never carry critical commands.
        await service.execute(device, command, confirmed: car);
      } on Object catch (e) {
        _log.warning('tile command failed', e.runtimeType);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(quickTileStatesProvider, (_, _) => _push())
      ..listen(carButtonStatesProvider, (_, _) => _push())
      ..listen(syncStatusProvider, (_, next) {
        if (next == SyncStatus.live) unawaited(_run());
      });
    return widget.child;
  }
}
