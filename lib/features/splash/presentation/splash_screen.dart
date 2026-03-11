import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:rideglory/features/splash/presentation/widgets/splash_brand_content.dart';
import 'package:rideglory/features/splash/presentation/widgets/splash_footer.dart';
import 'package:rideglory/features/splash/presentation/widgets/splash_glow_background.dart';
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

    if (splashState is SplashLoading || splashState is SplashInitial) return;

    if (splashState is SplashUnauthenticated) {
      _hasNavigated = true;
      if (mounted) context.pushReplacementNamed(AppRoutes.login);
      return;
    }

    if (splashState is SplashAuthenticated) {
      _hasNavigated = true;
      if (mounted) context.pushReplacementNamed(AppRoutes.home);
      return;
    }
  }

  void _onRetry() {
    setState(() {
      _hasNavigated = false;
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
