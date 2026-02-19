import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/presentation/widgets/social_login_button.dart';
import 'package:rideglory/features/authentication/presentation/widgets/email_input_field.dart';
import 'package:rideglory/features/authentication/presentation/widgets/password_input_field.dart';
import 'package:rideglory/features/authentication/presentation/widgets/auth_button.dart';
import 'package:rideglory/features/authentication/presentation/widgets/auth_text_with_link.dart';
import 'package:rideglory/features/authentication/presentation/widgets/divider_with_text.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return AuthStrings.emailRequired;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value!)) {
      return AuthStrings.invalidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return AuthStrings.passwordRequired;
    }
    if (value!.length < 6) {
      return AuthStrings.passwordMinLength;
    }
    return null;
  }

  void _handleEmailLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  content: Text(state.errorMessage ?? AppStrings.errorOccurred),
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
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      EmailInputField(
                        controller: _emailController,
                        validator: _validateEmail,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: () {
                          _passwordFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      PasswordInputField(
                        controller: _passwordController,
                        validator: _validatePassword,
                        label: AuthStrings.enterPassword,
                        textInputAction: TextInputAction.done,
                        focusNode: _passwordFocusNode,
                        onFieldSubmitted: _handleEmailLogin,
                      ),
                      const SizedBox(height: 24),

                      // Sign in button
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          return AuthButton(
                            label: AuthStrings.signIn,
                            onPressed: _handleEmailLogin,
                            isLoading: state.isLoading,
                          );
                        },
                      ),
                    ],
                  ),
                ),
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
    );
  }
}
