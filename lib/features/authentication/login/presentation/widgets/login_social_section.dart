import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_social_button.dart';

enum LoginAuthProvider { google, apple }

class LoginSocialSection extends StatefulWidget {
  const LoginSocialSection({super.key});

  @override
  State<LoginSocialSection> createState() => _LoginSocialSectionState();
}

class _LoginSocialSectionState extends State<LoginSocialSection> {
  LoginAuthProvider? _loadingProvider;

  AnalyticsService get _analytics => getIt<AnalyticsService>();

  void _onPressed(LoginAuthProvider provider, VoidCallback action) {
    setState(() => _loadingProvider = provider);
    final method = provider == LoginAuthProvider.google
        ? AnalyticsParams.authMethodGoogle
        : AnalyticsParams.authMethodApple;
    _analytics
        .logEvent(AnalyticsEvents.authMethodSelected, {
          AnalyticsParams.authMethod: method,
        })
        .ignore();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (!state.isLoading) {
          setState(() => _loadingProvider = null);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (Platform.isAndroid)
            LoginSocialButton(
              label: context.l10n.auth_continue_with_google,
              icon: Icons.g_mobiledata_rounded,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              isLoading: _loadingProvider == LoginAuthProvider.google,
              isDisabled: _loadingProvider != null,
              onPressed: () => _onPressed(
                LoginAuthProvider.google,
                () => context.read<AuthCubit>().signInWithGoogle(),
              ),
            ),
          if (Platform.isIOS)
            LoginSocialButton(
              label: context.l10n.auth_appleLabel,
              icon: Icons.apple,
              backgroundColor: Colors.black,
              textColor: Colors.white,
              isLoading: _loadingProvider == LoginAuthProvider.apple,
              isDisabled: _loadingProvider != null,
              onPressed: () => _onPressed(
                LoginAuthProvider.apple,
                () => context.read<AuthCubit>().signInWithApple(),
              ),
            ),
        ],
      ),
    );
  }
}
