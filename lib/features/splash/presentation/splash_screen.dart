import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SplashCubit>()..initialize(),
      child: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) async {
          state.whenOrNull(
            navigateToLogin: () =>
                context.pushReplacementNamed(AppRoutes.login),
            navigateToOnboarding: () =>
                context.pushReplacementNamed(AppRoutes.vehicleOnboarding),
            navigateToHome: () =>
                context.pushReplacementNamed(AppRoutes.maintenances),
            fetchSelectedVehicle: (vehicles) =>
                context.read<SplashCubit>().fetchSelectedVehicle(vehicles),
            fetchSelectedVehicleSuccess: (selectedVehicle) {
              context.read<VehicleCubit>().setCurrentVehicle(selectedVehicle);
            },
          );
        },
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
      ),
    );
  }
}
