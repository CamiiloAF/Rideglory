import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/application/auth_cubit.dart';
import '../../features/authentication/login/presentation/login_view.dart';
import '../../features/authentication/signup/presentation/signup_view.dart';
import '../../features/maintenance/presentation/form/maintenance_form_page.dart';
import '../../features/maintenance/presentation/list/maintenances/maintenances_page.dart';
import '../../features/vehicles/presentation/form/vehicle_form_page.dart';
import '../../features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';
import '../../features/vehicles/presentation/list/vehicle_list_page.dart';
import '../../features/vehicles/presentation/views/vehicle_onboarding_view.dart';
import '../../core/domain/result_state.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter appRouter(BuildContext context) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.login,
  redirect: (BuildContext context, GoRouterState state) {
    // Get auth state
    final authCubit = context.read<AuthCubit>();
    final isAuthenticated = authCubit.state.isAuthenticated;

    // Get vehicle state
    final vehicleListCubit = context.read<VehicleListCubit>();
    final hasVehicles = vehicleListCubit.state.maybeWhen(
      data: (vehicles) => vehicles.isNotEmpty,
      orElse: () => false,
    );

    // Check if user is on login/signup pages
    final isOnAuthPage =
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.signup;

    final isOnOnboarding = state.matchedLocation == AppRoutes.vehicleOnboarding;

    // If not authenticated and not on auth page, redirect to login
    if (!isAuthenticated && !isOnAuthPage) {
      return AppRoutes.login;
    }

    // If authenticated
    if (isAuthenticated) {
      // If on auth page and has vehicles, redirect to maintenances
      if (isOnAuthPage && hasVehicles) {
        return AppRoutes.maintenances;
      }

      // If on auth page and no vehicles, redirect to onboarding
      if (isOnAuthPage && !hasVehicles) {
        return AppRoutes.vehicleOnboarding;
      }

      // If not on onboarding and no vehicles, redirect to onboarding
      if (!isOnOnboarding && !hasVehicles) {
        return AppRoutes.vehicleOnboarding;
      }
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
        final vehicleId = state.pathParameters['id'];
        if (vehicleId == null) {
          return const Scaffold(
            body: Center(child: Text('Invalid vehicle ID')),
          );
        }

        // Find vehicle in list
        final vehicleListCubit = context.read<VehicleListCubit>();
        final vehicle = vehicleListCubit.state.maybeWhen(
          data: (vehicles) => vehicles.firstWhere(
            (v) => v.id == vehicleId,
            orElse: () => throw Exception('Vehicle not found'),
          ),
          orElse: () => null,
        );

        if (vehicle == null) {
          return const Scaffold(body: Center(child: Text('Vehicle not found')));
        }

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
