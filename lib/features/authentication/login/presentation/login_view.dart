import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/presentation/widgets/social_login_button.dart';
import 'package:rideglory/features/authentication/presentation/widgets/auth_text_with_link.dart';
import 'package:rideglory/features/authentication/presentation/widgets/divider_with_text.dart';
import 'package:rideglory/features/authentication/presentation/widgets/login_email_form.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormBuilderState>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ConfirmationDialog.show(
          context: context,
          title: AuthStrings.exitLoginTitle,
          content: AuthStrings.exitLoginMessage,
          onConfirm: () => SystemNavigator.pop(),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state.isAuthenticatedWithVehicles) {
                context.pushReplacementNamed(AppRoutes.maintenances);
              } else if (state.isAuthenticatedWithoutVehicles) {
                context.pushReplacementNamed(AppRoutes.vehicleOnboarding);
              } else if (state.hasError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.errorMessage ?? AppStrings.errorOccurred,
                    ),
                    backgroundColor: context.errorColor,
                  ),
                );
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AuthStrings.letsStart, style: context.displayLarge),
                      const SizedBox(height: 8),
                      Text(
                        AuthStrings.loginSubtitle,
                        style: context.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Email/Password Form
                  LoginEmailForm(formKey: formKey),
                  const SizedBox(height: 32),

                  // Sign up section
                  Center(
                    child: AuthTextWithLink(
                      text: '${AuthStrings.dontHaveAccount} ',
                      linkText: AuthStrings.createAccountLink,
                      onLinkTap: () => context.push(AppRoutes.signup),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Divider
                  const DividerWithText(text: AuthStrings.orContinueWith),
                  const SizedBox(height: 24),

                  // Social Login Buttons
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isLoading = state.isLoading;
                      return Column(
                        children: [
                          SocialLoginButton(
                            type: SocialLoginType.google,
                            isLoading: isLoading,
                            onPressed: () {
                              context.read<AuthCubit>().signInWithGoogle();
                            },
                          ),
                          // const SizedBox(height: 12),
                          // SocialLoginButton(
                          //   type: SocialLoginType.apple,
                          //   isLoading: isLoading,
                          //   onPressed: () {
                          //     context.read<AuthCubit>().signInWithApple();
                          //   },
                          // ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
