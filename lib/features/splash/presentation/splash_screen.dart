import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:rideglory/features/splash/presentation/widgets/splash_brand_content.dart';
import 'package:rideglory/features/splash/presentation/widgets/splash_footer.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/modals/app_modal.dart';
import 'package:rideglory/shared/widgets/modals/app_modal_action.dart';
import 'package:url_launcher/url_launcher.dart';

const _androidStoreUrl =
    'https://play.google.com/store/apps/details?id=com.camiloagudelo.rideglory';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SplashCubit>(
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

  void _handleNavigation(BuildContext context, SplashState state) async {
    if (_hasNavigated) return;

    if (state is SplashLoading || state is SplashInitial) return;

    if (state is SplashForceUpdate) {
      if (mounted) {
        AppModal.show(
          context: context,
          variant: AppModalVariant.warning,
          icon: Icons.system_update_rounded,
          title: context.l10n.splash_forceUpdateTitle,
          description: context.l10n.splash_forceUpdateMessage,
          actions: [
            AppModalAction(
              label: context.l10n.splash_forceUpdateButton,
              onPressed: _openStore,
            ),
          ],
        );
      }
      return;
    }

    if (state is SplashUnauthenticated) {
      _hasNavigated = true;
      if (mounted) context.pushReplacementNamed(AppRoutes.login);
      return;
    }

    if (state is SplashAuthenticated) {
      _hasNavigated = true;
      if (mounted) {
        // LoadCurrentUserUseCase ya seteó _authService._currentUser; sincronizamos AuthCubit.
        context.read<AuthCubit>().checkAuthState();
        context.pushReplacementNamed(AppRoutes.home);
      }
      return;
    }
  }

  Future<void> _openStore() async {
    final url = Uri.parse(
      defaultTargetPlatform == TargetPlatform.iOS
          ? _androidStoreUrl
          : _androidStoreUrl,
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
    return BlocListener<SplashCubit, SplashState>(
      listener: _handleNavigation,
      child: Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        body: Stack(
          children: [
            const SplashBrandContent(),
            SplashFooter(
              progressAnimation: _progressAnimation,
              onRetry: _onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
