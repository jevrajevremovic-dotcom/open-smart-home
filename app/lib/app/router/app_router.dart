import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/application/session_controller.dart';
import '../../features/connection/application/connection_setup_controller.dart';
import '../../features/connection/presentation/server_address_screen.dart';
import '../../features/connection/presentation/token_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/devices/presentation/device_detail_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/rooms/presentation/rooms_screen.dart';
import '../../features/scenes/presentation/scenes_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'app_shell.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const connectServer = '/connect/server';
  static const connectToken = '/connect/token';
  static const home = '/home';
  static const rooms = '/rooms';
  static const allDevices = '/devices';
  static const favorites = '/favorites';
  static const scenes = '/scenes';
  static const settings = '/settings';

  /// Path segment used for "devices without a room".
  static const noRoomId = '_unassigned';

  static String room(String? id) =>
      '$rooms/${Uri.encodeComponent(id ?? noRoomId)}';
  static String device(String id) => '/device/${Uri.encodeComponent(id)}';

  /// Destinations shown in the bottom bar / navigation rail, in order.
  static const shellDestinations = [home, rooms, favorites, scenes, settings];

  /// Which destination is highlighted for a location.
  static int shellIndexFor(String location) {
    if (location.startsWith(rooms) ||
        location.startsWith(allDevices) ||
        location.startsWith('/device/')) {
      return 1;
    }
    final index = shellDestinations.indexWhere(location.startsWith);
    return index < 0 ? 0 : index;
  }
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
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.rooms,
            pageBuilder: (_, _) => const NoTransitionPage(child: RoomsScreen()),
            routes: [
              GoRoute(
                path: ':roomId',
                builder: (_, state) {
                  final id = state.pathParameters['roomId']!;
                  return RoomDetailScreen(
                    roomId: id == AppRoutes.noRoomId ? null : id,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.allDevices,
            builder: (_, _) => const AllDevicesScreen(),
          ),
          GoRoute(
            path: '/device/:deviceId',
            builder: (_, state) =>
                DeviceDetailScreen(deviceId: state.pathParameters['deviceId']!),
          ),
          GoRoute(
            path: AppRoutes.favorites,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: FavoritesScreen()),
          ),
          GoRoute(
            path: AppRoutes.scenes,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: ScenesScreen()),
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
