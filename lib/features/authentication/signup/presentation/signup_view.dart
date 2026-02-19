import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/presentation/widgets/social_login_button.dart';
import 'package:rideglory/features/authentication/presentation/widgets/email_input_field.dart';
import 'package:rideglory/features/authentication/presentation/widgets/password_input_field.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

/// Modern sign-up view for creating a new account
class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _acceptedTerms = false;
  bool _isEmailMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
    if (value!.length < 8) {
      return AuthStrings.passwordMinLength8;
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return AuthStrings.passwordNeedsUppercase;
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return AuthStrings.passwordNeedsNumber;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return AuthStrings.confirmPasswordRequired;
    }
    if (value != _passwordController.text) {
      return AuthStrings.passwordsDoNotMatch;
    }
    return null;
  }

  void _handleEmailSignup() {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthStrings.acceptTermsError),
          backgroundColor: context.errorColor,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
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
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEmailMode
                          ? AuthStrings.createAccount
                          : AuthStrings.joinToday,
                      style: context.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEmailMode
                          ? AuthStrings.signupSubtitleEmail
                          : AuthStrings.signupSubtitleSocial,
                      style: context.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Social Sign-up Buttons (visible when not in email mode)
                if (!_isEmailMode) ...[
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isLoading = state.isLoading;
                      return Column(
                        children: [
                          SocialLoginButton(
                            type: SocialLoginType.email,
                            isLoading: isLoading,
                            onPressed: () {
                              setState(() => _isEmailMode = true);
                            },
                          ),
                          const SizedBox(height: 12),
                          SocialLoginButton(
                            type: SocialLoginType.google,
                            isLoading: isLoading,
                            onPressed: () {
                              context.read<AuthCubit>().signInWithGoogle();
                            },
                          ),
                          const SizedBox(height: 12),
                          SocialLoginButton(
                            type: SocialLoginType.apple,
                            isLoading: isLoading,
                            onPressed: () {
                              context.read<AuthCubit>().signInWithApple();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 1, color: Colors.grey[200]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '¿Ya tienes cuenta?',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(height: 1, color: Colors.grey[200]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign in link
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: '${AuthStrings.signIn} ',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => context.pop(),
                              child: Text(
                                AuthStrings.signInLink,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
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
                          label: AuthStrings.createPassword,
                          textInputAction: TextInputAction.next,
                          focusNode: _passwordFocusNode,
                          onFieldSubmitted: () {
                            _confirmPasswordFocusNode.requestFocus();
                          },
                        ),
                        const SizedBox(height: 16),
                        PasswordInputField(
                          controller: _confirmPasswordController,
                          validator: _validateConfirmPassword,
                          label: AuthStrings.confirmYourPassword,
                          textInputAction: TextInputAction.done,
                          focusNode: _confirmPasswordFocusNode,
                          onFieldSubmitted: _handleEmailSignup,
                        ),
                        const SizedBox(height: 24),

                        // Terms and conditions checkbox
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(
                                      () => _acceptedTerms = !_acceptedTerms,
                                    );
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _acceptedTerms
                                            ? const Color(0xFF6366F1)
                                            : Colors.grey[300]!,
                                        width: 2,
                                      ),
                                      color: _acceptedTerms
                                          ? const Color(0xFF6366F1)
                                          : Colors.transparent,
                                    ),
                                    child: _acceptedTerms
                                        ? const Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(
                                      () => _acceptedTerms = !_acceptedTerms,
                                    );
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: AuthStrings.acceptTerms,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: [
                                        const TextSpan(
                                          text: AuthStrings.termsOfService,
                                          style: TextStyle(
                                            color: Color(0xFF6366F1),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' y ',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const TextSpan(
                                          text: AuthStrings.privacyPolicy,
                                          style: TextStyle(
                                            color: Color(0xFF6366F1),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign up button
                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            final isLoading = state.isLoading;
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: .3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: isLoading ? null : _handleEmailSignup,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Center(
                                      child: isLoading
                                          ? SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              AuthStrings.createAccount,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Back button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isEmailMode = false;
                                  _emailController.clear();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Center(
                                  child: Text(
                                    AppStrings.back,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
