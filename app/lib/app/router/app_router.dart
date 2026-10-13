import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/application/session_controller.dart';
import '../../features/connection/application/connection_setup_controller.dart';
import '../../features/connection/presentation/server_address_screen.dart';
import '../../features/connection/presentation/token_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'app_shell.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const connectServer = '/connect/server';
  static const connectToken = '/connect/token';
  static const home = '/home';
  static const settings = '/settings';

  /// Destinations shown in the bottom bar / navigation rail.
  static const shellDestinations = [home, settings];
}

/// Pure redirect rules, separated for unit testing.
String? resolveRedirect({
  required String location,
  required bool sessionLoading,
  required bool signedIn,
  required bool serverChosen,
}) {
  if (sessionLoading) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  final inOnboarding =
      location == AppRoutes.welcome || location.startsWith('/connect');
  if (!signedIn) {
    if (location == AppRoutes.connectToken && !serverChosen) {
      return AppRoutes.connectServer;
    }
    return inOnboarding ? null : AppRoutes.welcome;
  }
  if (inOnboarding || location == AppRoutes.splash) return AppRoutes.home;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionControllerProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      return resolveRedirect(
        location: state.matchedLocation,
        sessionLoading: session.isLoading && !session.hasValue,
        signedIn: session.value != null,
        serverChosen:
            ref.read(connectionSetupControllerProvider).profile != null,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.connectServer,
        builder: (_, _) => const ServerAddressScreen(),
      ),
      GoRoute(
        path: AppRoutes.connectToken,
        builder: (_, _) => const TokenScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (_, _) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
