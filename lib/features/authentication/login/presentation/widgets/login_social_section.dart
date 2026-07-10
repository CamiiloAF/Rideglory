import 'dart:io' show Platform;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/config/api_remote_config.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/google_logo_icon.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_social_button.dart';

enum LoginAuthProvider { google, apple }

class LoginSocialSection extends StatefulWidget {
  const LoginSocialSection({super.key});

  // `Platform.isAndroid`/`Platform.isIOS` are `static final` in dart:io and
  // reflect the actual host OS, so they cannot be faked from a `flutter test`
  // run on a dev machine (it always reports the host OS, e.g. macOS/Linux —
  // never android/ios). These test-only overrides let widget tests force
  // either branch to render so the mutual-exclusion logic can be exercised.
  // They stay `null` in production, so real behavior is untouched.
  @visibleForTesting
  static bool? debugIsAndroidOverride;

  @visibleForTesting
  static bool? debugIsIOSOverride;

  @override
  State<LoginSocialSection> createState() => _LoginSocialSectionState();
}

class _LoginSocialSectionState extends State<LoginSocialSection> {
  LoginAuthProvider? _loadingProvider;

  AnalyticsService get _analytics => getIt<AnalyticsService>();

  bool get _googleSignInIosEnabled => getIt<FirebaseRemoteConfig>().getBool(
    ApiRemoteConfig.googleSignInIosEnabledKey,
  );

  void _onPressed(LoginAuthProvider provider, VoidCallback action) {
    setState(() => _loadingProvider = provider);
    final method = provider == LoginAuthProvider.google
        ? AnalyticsParams.authMethodGoogle
        : AnalyticsParams.authMethodApple;
    _analytics.logEvent(AnalyticsEvents.authMethodSelected, {
      AnalyticsParams.authMethod: method,
    }).ignore();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid =
        LoginSocialSection.debugIsAndroidOverride ?? Platform.isAndroid;
    final isIOS = LoginSocialSection.debugIsIOSOverride ?? Platform.isIOS;
    final showGoogleOnIos = isIOS && _googleSignInIosEnabled;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (!state.isLoading) {
          setState(() => _loadingProvider = null);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isAndroid || showGoogleOnIos)
            LoginSocialButton(
              label: context.l10n.auth_continue_with_google,
              // Branding oficial "Sign in with Google" (tema claro): fondo
              // blanco, "G" multicolor, texto #1F1F1F y borde #747775.
              customIcon: const GoogleLogoIcon(),
              backgroundColor: Colors.white,
              textColor: const Color(0xFF1F1F1F),
              borderColor: const Color(0xFF747775),
              isLoading: _loadingProvider == LoginAuthProvider.google,
              isDisabled: _loadingProvider != null,
              onPressed: () => _onPressed(
                LoginAuthProvider.google,
                () => context.read<AuthCubit>().signInWithGoogle(),
              ),
            ),
          if ((isAndroid || showGoogleOnIos) && isIOS)
            const SizedBox(height: 12),
          if (isIOS)
            LoginSocialButton(
              label: context.l10n.auth_appleLabel,
              icon: Icons.apple,
              backgroundColor: Colors.white,
              textColor: Colors.black,
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
