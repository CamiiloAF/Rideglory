import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/application/auth_cubit.dart';
import '../../features/authentication/login/presentation/login_view.dart';
import '../../features/authentication/signup/presentation/signup_view.dart';
import '../../features/maintenance/presentation/form/maintenance_form_page.dart';
import '../../features/maintenance/presentation/list/maintenances/maintenances_page.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter appRouter(BuildContext context) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.login,
  redirect: (BuildContext context, GoRouterState state) {
    // Get auth state
    final authCubit = context.read<AuthCubit>();
    final isAuthenticated = authCubit.state.isAuthenticated;

    // Check if user is on login/signup pages
    final isOnAuthPage =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.signup;

    // If not authenticated and not on auth page, redirect to login
    if (!isAuthenticated && !isOnAuthPage) {
      return AppRoutes.login;
    }

    // If authenticated and on auth page, redirect to maintenances
    if (isAuthenticated && isOnAuthPage) {
      return AppRoutes.maintenances;
    }

    return null; // No redirect needed
  },
  refreshListenable: GoRouterRefreshStream(context.read<AuthCubit>().stream),
  routes: <RouteBase>[
    // Authentication routes
    GoRoute(
      path: AppRoutes.login,
      name: AppRoutes.login,
      builder: (context, state) {
        return const LoginView();
      },
    ),
    GoRoute(
      path: AppRoutes.signup,
      name: AppRoutes.signup,
      builder: (context, state) {
        return const SignupView();
      },
    ),

    // Maintenance routes
    GoRoute(
      path: AppRoutes.maintenances,
      name: AppRoutes.maintenances,
      builder: (context, state) {
        return const MaintenancesPage();
      },
    ),
    GoRoute(
      path: AppRoutes.createMaintenance,
      name: AppRoutes.createMaintenance,
      builder: (context, state) {
        return const MaintenanceFormPage();
      },
    ),
  ],
);

/// Stream-based GoRouter refresh listener
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
