import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SplashCubit>()..initialize(),
      child: const _SplashScreenContent(),
    );
  }
}

class _SplashScreenContent extends StatefulWidget {
  const _SplashScreenContent();

  @override
  State<_SplashScreenContent> createState() => _SplashScreenContentState();
}

class _SplashScreenContentState extends State<_SplashScreenContent> {
  bool _hasNavigated = false;
  bool _hasLoadedVehicles = false;

  void _handleNavigation() async {
    if (_hasNavigated) return;

    final splashState = context.read<SplashCubit>().state;
    final vehicleListState = context.read<VehicleListCubit>().state;

    // Wait for authentication check
    if (splashState is SplashLoading || splashState is SplashInitial) {
      return;
    }

    // Handle unauthenticated state
    if (splashState is SplashUnauthenticated) {
      _hasNavigated = true;
      if (mounted) {
        context.pushReplacementNamed(AppRoutes.login);
      }
      return;
    }

    // User is authenticated, load vehicles if not already loaded
    if (splashState is SplashAuthenticated) {
      if (!_hasLoadedVehicles) {
        _hasLoadedVehicles = true;
        context.read<VehicleListCubit>().loadVehicles();
        return;
      }

      // Wait for vehicles to load
      if (vehicleListState is Initial || vehicleListState is Loading) {
        return;
      }

      // Handle vehicle states
      if (vehicleListState is Empty) {
        // No vehicles, go to onboarding
        _hasNavigated = true;
        if (mounted) {
          context.pushReplacementNamed(AppRoutes.vehicleOnboarding);
        }
        return;
      }

      if (vehicleListState is Data<List<VehicleModel>>) {
        // Has vehicles, select current and navigate to home
        _hasNavigated = true;

        final vehicles = vehicleListState.data;
        final selectedVehicle =
            await context.read<SplashCubit>().getSelectedVehicle(vehicles);

        if (selectedVehicle != null && mounted) {
          context.read<VehicleCubit>().setCurrentVehicle(selectedVehicle);
          context.pushReplacementNamed(AppRoutes.maintenances);
        }
        return;
      }

      if (vehicleListState is Error) {
        // Error loading vehicles, go to login to retry
        _hasNavigated = true;
        if (mounted) {
          context.pushReplacementNamed(AppRoutes.login);
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen to SplashCubit state changes
        BlocListener<SplashCubit, SplashState>(
          listener: (context, state) {
            _handleNavigation();
          },
        ),
        // Listen to VehicleListCubit state changes
        BlocListener<VehicleListCubit, ResultState<List<VehicleModel>>>(
          listener: (context, state) {
            _handleNavigation();
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF6366F1),
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    size: 64,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 32),
                // App name
                const Text(
                  'RideGlory',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vehicle Maintenance Tracker',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                // Loading indicator
                BlocBuilder<SplashCubit, SplashState>(
                  builder: (context, state) {
                    if (state is SplashError) {
                      return Column(
                        children: [
                          Text(
                            'Error: ${state.message}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _hasNavigated = false;
                                _hasLoadedVehicles = false;
                              });
                              context.read<SplashCubit>().initialize();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      );
                    }
                    return const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
  }
}
