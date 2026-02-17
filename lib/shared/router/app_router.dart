import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

import '../../features/authentication/application/auth_cubit.dart';
import '../../features/authentication/login/presentation/login_view.dart';
import '../../features/authentication/signup/presentation/signup_view.dart';
import '../../features/maintenance/presentation/form/maintenance_form_page.dart';
import '../../features/maintenance/presentation/list/maintenances/maintenances_page.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/vehicles/presentation/form/vehicle_form_page.dart';
import '../../features/vehicles/presentation/list/vehicle_list_page.dart';
import '../../features/vehicles/presentation/views/vehicle_onboarding_view.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter appRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (BuildContext context, GoRouterState state) {
      final authCubit = context.read<AuthCubit>();
      final isAuthenticated = authCubit.state.isAuthenticated;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnAuthPage =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;

      // Allow access to splash and auth pages
      if (isOnSplash || isOnAuthPage) {
        return null;
      }

      // Protect authenticated routes
      if (!isAuthenticated) {
        return AppRoutes.login;
      }

      return null; // No redirect needed
    },
    refreshListenable: GoRouterRefreshStream(getIt.get<AuthCubit>().stream),
    routes: <RouteBase>[
      // Splash route
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splash,
        builder: (context, state) {
          return const SplashScreen();
        },
      ),

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

      // Onboarding routes
      GoRoute(
        path: AppRoutes.vehicleOnboarding,
        name: AppRoutes.vehicleOnboarding,
        builder: (context, state) {
          return const VehicleOnboardingView();
        },
      ),

      // Vehicle routes
      GoRoute(
        path: AppRoutes.vehicles,
        name: AppRoutes.vehicles,
        builder: (context, state) {
          return const VehicleListPage();
        },
      ),
      GoRoute(
        path: AppRoutes.createVehicle,
        name: AppRoutes.createVehicle,
        builder: (context, state) {
          return const VehicleFormPage();
        },
      ),
      GoRoute(
        path: AppRoutes.editVehicle,
        name: AppRoutes.editVehicle,
        builder: (context, state) {
          final vehicle = state.extra as VehicleModel?;
          return VehicleFormPage(vehicle: vehicle);
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
      GoRoute(
        path: AppRoutes.editMaintenance,
        name: AppRoutes.editMaintenance,
        builder: (context, state) {
          final maintenance = state.extra as MaintenanceModel?;
          return MaintenanceFormPage(maintenance: maintenance);
        },
      ),
    ],
  );
}

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
