import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/app_lock/application/app_lock.dart';
import '../features/app_lock/presentation/app_lock_gate.dart';
import '../features/authentication/application/session_controller.dart';
import '../features/authentication/data/session_repository.dart';
import '../features/devices/application/device_providers.dart';
import '../features/settings/application/appearance_controllers.dart';
import '../features/shortcuts/app_shortcuts.dart';
import 'localization/app_locales.dart';
import 'localization/l10n.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SmartHomeApp extends ConsumerStatefulWidget {
  const SmartHomeApp({super.key});

  @override
  ConsumerState<SmartHomeApp> createState() => _SmartHomeAppState();
}

class _SmartHomeAppState extends ConsumerState<SmartHomeApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back in the foreground (or a wall panel waking up): reconnect now
    // instead of waiting for the remaining backoff delay.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(appLockProvider.notifier).onForeground();
        ref.read(webSocketManagerProvider)?.retryNow();
      },
      // Persist the offline cache before the OS may suspend or kill us.
      onPause: () => ref.read(homeStateRepositoryProvider)?.flush(),
      onHide: () {
        ref.read(appLockProvider.notifier).onBackground();
        ref.read(homeStateRepositoryProvider)?.flush();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Remember each home's name for the home switcher.
    ref.listen(serverConfigProvider, (_, next) {
      final profile = ref.read(activeProfileProvider);
      final name = next.value?.locationName;
      if (profile == null || name == null) return;
      ref
          .read(sessionRepositoryProvider)
          .setHomeName(profile.id, name)
          .then((_) => ref.invalidate(savedHomesProvider));
    });
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: AppLocales.resolve,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          ShortcutsHost(child: AppLockGate(child: child ?? const SizedBox())),
    );
  }
}
