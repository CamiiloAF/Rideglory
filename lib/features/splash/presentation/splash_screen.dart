import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:rideglory/features/splash/presentation/widgets/splash_brand_content.dart';
import 'package:rideglory/features/splash/presentation/widgets/splash_footer.dart';
import 'package:rideglory/features/splash/presentation/widgets/splash_glow_background.dart';
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
      child: const _SplashContent(),
    );
  }
}

class _SplashContent extends StatefulWidget {
  const _SplashContent();

  @override
  State<_SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<_SplashContent>
    with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  bool _hasLoadedVehicles = false;

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _handleNavigation() async {
    if (_hasNavigated) return;

    final splashState = context.read<SplashCubit>().state;
    final vehicleListState = context.read<VehicleListCubit>().state;

    if (splashState is SplashLoading || splashState is SplashInitial) return;

    if (splashState is SplashUnauthenticated) {
      _hasNavigated = true;
      if (mounted) context.pushReplacementNamed(AppRoutes.login);
      return;
    }

    if (splashState is SplashAuthenticated) {
      if (!_hasLoadedVehicles) {
        _hasLoadedVehicles = true;
        context.read<VehicleListCubit>().loadVehicles();
        return;
      }

      if (vehicleListState is Initial || vehicleListState is Loading) return;

      if (vehicleListState is Empty) {
        _hasNavigated = true;
        if (mounted) context.pushReplacementNamed(AppRoutes.vehicleOnboarding);
        return;
      }

      if (vehicleListState is Data<List<VehicleModel>>) {
        _hasNavigated = true;
        final vehicles = vehicleListState.data;
        final selectedVehicle = await context
            .read<SplashCubit>()
            .getSelectedVehicle(vehicles);

        if (selectedVehicle != null && mounted) {
          context.read<VehicleCubit>().setCurrentVehicle(selectedVehicle);
          context.pushReplacementNamed(AppRoutes.home);
        }
        return;
      }

      if (vehicleListState is Error) {
        _hasNavigated = true;
        if (mounted) context.pushReplacementNamed(AppRoutes.login);
        return;
      }
    }
  }

  void _onRetry() {
    setState(() {
      _hasNavigated = false;
      _hasLoadedVehicles = false;
    });
    context.read<SplashCubit>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SplashCubit, SplashState>(
          listener: (context, state) => _handleNavigation(),
        ),
        BlocListener<VehicleListCubit, ResultState<List<VehicleModel>>>(
          listener: (context, state) => _handleNavigation(),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Stack(
            children: [
              const SplashGlowBackground(),
              const SplashBrandContent(),
              SplashFooter(
                progressAnimation: _progressAnimation,
                onRetry: _onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
