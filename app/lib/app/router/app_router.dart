import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/application/session_controller.dart';
import '../../features/connection/application/connection_setup_controller.dart';
import '../../features/connection/presentation/server_address_screen.dart';
import '../../features/connection/presentation/token_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/devices/presentation/device_detail_screen.dart';
import '../../features/add_device/presentation/add_device_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/energy/presentation/energy_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/kiosk/application/kiosk_controller.dart';
import '../../features/kiosk/presentation/kiosk_dashboard_screen.dart';
import '../../features/kiosk/presentation/kiosk_shell.dart';
import '../../features/weather/presentation/weather_screen.dart';
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
  static const energy = '/energy';
  static const weather = '/weather';
  static const calendar = '/calendar';
  static const addDevice = '/add-device';
  static String weatherFor({bool kiosk = false}) =>
      '${kiosk ? AppRoutes.kiosk : ''}$weather';

  /// Path segment used for "devices without a room".
  static const noRoomId = '_unassigned';

  static const kiosk = '/kiosk';

  /// In kiosk mode links stay under [kiosk], so the router never lets the
  /// user out of the kiosk shell.
  static String room(String? id, {bool kiosk = false}) =>
      '${kiosk ? AppRoutes.kiosk : ''}$rooms/${Uri.encodeComponent(id ?? noRoomId)}';
  static String device(String id, {bool kiosk = false}) =>
      '${kiosk ? AppRoutes.kiosk : ''}/device/${Uri.encodeComponent(id)}';

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
  bool kioskActive = false,
  bool addingHome = false,
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
  final inKiosk =
      location == AppRoutes.kiosk || location.startsWith('${AppRoutes.kiosk}/');
  // While kiosk mode is active nothing outside the kiosk routes is reachable
  // (deep links, back navigation, …); leaving requires the PIN.
  if (kioskActive) return inKiosk ? null : AppRoutes.kiosk;
  if (inKiosk) return AppRoutes.home;
  // Adding another home: the connect screens stay reachable.
  if (addingHome && location.startsWith('/connect')) return null;
  if (inOnboarding || location == AppRoutes.splash) return AppRoutes.home;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(sessionControllerProvider, (_, _) => refresh.value++)
    ..listen(kioskActiveProvider, (_, _) => refresh.value++)
    ..listen(addingHomeProvider, (_, _) => refresh.value++);

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
        kioskActive: ref.read(kioskActiveProvider),
        addingHome: ref.read(addingHomeProvider),
      );
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            KioskShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.kiosk,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: KioskDashboardScreen()),
            routes: [
              GoRoute(
                path: 'device/:deviceId',
                builder: (_, state) => KioskScale(
                  child: DeviceDetailScreen(
                    deviceId: state.pathParameters['deviceId']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'weather',
                builder: (_, _) => const KioskScale(child: WeatherScreen()),
              ),
              GoRoute(
                path: 'rooms/:roomId',
                builder: (_, state) {
                  final id = state.pathParameters['roomId']!;
                  return KioskScale(
                    child: RoomDetailScreen(
                      roomId: id == AppRoutes.noRoomId ? null : id,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
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
            path: AppRoutes.energy,
            builder: (_, _) => const EnergyScreen(),
          ),
          GoRoute(
            path: AppRoutes.weather,
            builder: (_, _) => const WeatherScreen(),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            builder: (_, _) => const CalendarScreen(),
          ),
          GoRoute(
            path: AppRoutes.addDevice,
            builder: (_, _) => const AddDeviceScreen(),
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
