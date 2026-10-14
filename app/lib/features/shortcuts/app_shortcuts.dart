import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

import '../../app/localization/l10n.dart';
import '../../app/router/app_router.dart';
import '../assist/presentation/assist_sheet.dart';
import '../authentication/application/session_controller.dart';
import '../kiosk/application/kiosk_controller.dart';
import '../devices/application/device_providers.dart';
import '../devices/data/home_state_repository.dart';
import '../devices/domain/device_command.dart';
import '../devices/domain/device_kind.dart';
import '../devices/application/device_command_service.dart';
import '../favorites/application/favorites_controller.dart';
import '../restricted/application/restricted_mode.dart';

/// Long-press shortcuts on the app icon (Android / iOS).
abstract interface class AppShortcutsPlatform {
  bool get supported;
  void initialize(void Function(String type) onAction);
  Future<void> setItems(List<(String type, String title, String icon)> items);
}

class QuickActionsPlatform implements AppShortcutsPlatform {
  final QuickActions _qa = const QuickActions();

  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initialize(void Function(String type) onAction) =>
      _qa.initialize(onAction);

  @override
  Future<void> setItems(List<(String type, String title, String icon)> items) =>
      _qa.setShortcutItems([
        for (final (type, title, icon) in items)
          ShortcutItem(type: type, localizedTitle: title, icon: icon),
      ]);
}

final appShortcutsPlatformProvider = Provider<AppShortcutsPlatform>(
  (ref) => QuickActionsPlatform(),
);

/// A shortcut tapped before the app could act on it (e.g. still syncing).
class PendingShortcutController extends Notifier<String?> {
  @override
  String? build() => null;

  // ignore: use_setters_to_change_properties
  void set(String? type) => state = type;
}

final pendingShortcutProvider =
    NotifierProvider<PendingShortcutController, String?>(
      PendingShortcutController.new,
    );

/// Scenes offered as shortcuts: favourite scenes first, at most two.
final shortcutScenesProvider = Provider<List<(String, String)>>((ref) {
  final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
  final favorites = ref.watch(favoritesProvider);
  final scenes =
      devices.values.where((d) => d.kind == DeviceKind.scene).toList()
        ..sort((a, b) {
          final fa = favorites.indexOf(a.id);
          final fb = favorites.indexOf(b.id);
          if (fa != fb) {
            if (fa == -1) return 1;
            if (fb == -1) return -1;
            return fa.compareTo(fb);
          }
          return a.name.compareTo(b.name);
        });
  return [for (final s in scenes.take(2)) (s.id, s.name)];
});

/// Keeps the launcher shortcuts in sync and runs scene shortcuts once the
/// home is live. Kiosk and Assist shortcuts are handled by the screens.
class AppShortcutsBinder {
  AppShortcutsBinder(this.ref);

  final WidgetRef ref;
  bool _initialized = false;

  void bind(AppLocalizations l10n) {
    final platform = ref.read(appShortcutsPlatformProvider);
    if (!platform.supported) return;
    if (!_initialized) {
      _initialized = true;
      platform.initialize(
        (type) => ref.read(pendingShortcutProvider.notifier).set(type),
      );
    }
    final restricted = ref.read(restrictedModeProvider).enabled;
    final scenes = ref.read(shortcutScenesProvider);
    unawaited(
      platform.setItems([
        for (final (id, name) in scenes) ('scene:$id', name, 'ic_scene'),
        if (!restricted) ('assist', l10n.assistTitle, 'ic_assist'),
        if (!restricted) ('kiosk', l10n.kioskStart, 'ic_kiosk'),
      ]),
    );
  }

  /// Activates a pending scene shortcut once data is live.
  Future<void> runPendingScene() async {
    final type = ref.read(pendingShortcutProvider);
    if (type == null || !type.startsWith('scene:')) return;
    if (ref.read(syncStatusProvider) != SyncStatus.live) return;
    ref.read(pendingShortcutProvider.notifier).set(null);
    final device = ref.read(deviceProvider(type.substring(6)));
    final service = ref.read(deviceCommandServiceProvider);
    if (device == null || service == null) return;
    try {
      await service.execute(device, const Activate());
    } on Object {
      // Shown nowhere: the user sees the result in the home itself.
    }
  }
}

/// Sits below MaterialApp: keeps shortcuts current and acts on them.
class ShortcutsHost extends ConsumerStatefulWidget {
  const ShortcutsHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ShortcutsHost> createState() => _ShortcutsHostState();
}

class _ShortcutsHostState extends ConsumerState<ShortcutsHost> {
  late final AppShortcutsBinder _binder = AppShortcutsBinder(ref);

  void _handle(String? type) {
    if (type == null) return;
    final router = ref.read(routerProvider);
    final signedIn = ref.read(activeProfileProvider) != null;
    if (!signedIn) return;
    switch (type) {
      case 'kiosk':
        ref.read(pendingShortcutProvider.notifier).set(null);
        ref.read(kioskActiveProvider.notifier).enter();
        router.go(AppRoutes.kiosk);
      case 'assist':
        ref.read(pendingShortcutProvider.notifier).set(null);
        router.go(AppRoutes.home);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = router.routerDelegate.navigatorKey.currentContext;
          if (ctx != null) showAssist(ctx);
        });
      default:
        unawaited(_binder.runPendingScene());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref
      ..listen(shortcutScenesProvider, (_, _) => _binder.bind(l10n))
      ..listen(
        restrictedModeProvider.select((s) => s.enabled),
        (_, _) => _binder.bind(l10n),
      )
      ..listen(pendingShortcutProvider, (_, next) => _handle(next))
      ..listen(syncStatusProvider, (_, s) {
        if (s == SyncStatus.live) unawaited(_binder.runPendingScene());
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _binder.bind(l10n);
    });
    return widget.child;
  }
}
