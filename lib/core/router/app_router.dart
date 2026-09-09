import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/events/presentation/pages/events_page.dart';
import '../../features/garage/presentation/pages/garage_page.dart';
import '../../features/maintenance/presentation/pages/maintenance_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/maintenance/presentation/maintenance_routes.dart';
import '../../features/welcome/presentation/pages/welcome_page.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_state.dart';
import '../di/injection.dart';
import 'app_routes.dart';
import 'app_shell.dart';

/// Router raíz. La pestaña inicial es Mantenimiento (D4): es la única
/// parte de la app con uso real y recurrente.
GoRouter buildAppRouter() {
  final authCubit = getIt<AuthCubit>();

  return GoRouter(
    initialLocation: AppRoutes.maintenancePath,
    refreshListenable: AuthCubitListenable(authCubit),
    redirect: (context, state) {
      final authState = authCubit.state;
      final isAtWelcome = state.matchedLocation == AppRoutes.welcomePath;

      return switch (authState) {
        AuthUnknown() => null,
        AuthUnauthenticated() => isAtWelcome ? null : AppRoutes.welcomePath,
        AuthAuthenticated() => isAtWelcome ? AppRoutes.maintenancePath : null,
      };
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcomePath,
        name: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.maintenancePath,
                name: AppRoutes.maintenance,
                builder: (context, state) => const MaintenancePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.eventsPath,
                name: AppRoutes.events,
                builder: (context, state) => const EventsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.garagePath,
                name: AppRoutes.garage,
                builder: (context, state) => const GaragePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profilePath,
                name: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      ...maintenanceRoutes,
    ],
  );
}

/// Adapta el `Cubit` de sesión a `Listenable` para que `go_router` re-evalúe
/// el `redirect` cada vez que cambia.
class AuthCubitListenable extends ChangeNotifier {
  AuthCubitListenable(this._authCubit) {
    _subscription = _authCubit.stream.listen((_) => notifyListeners());
  }

  final AuthCubit _authCubit;
  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
