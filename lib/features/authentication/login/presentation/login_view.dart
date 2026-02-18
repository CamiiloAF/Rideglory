import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/presentation/widgets/social_login_button.dart';
import 'package:rideglory/features/authentication/presentation/widgets/email_input_field.dart';
import 'package:rideglory/features/authentication/presentation/widgets/password_input_field.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Modern login view with email, Google, and Apple sign-in options
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
      return 'El email es requerido';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value!)) {
      return 'Dirección de correo inválida';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'La contraseña es requerida';
    }
    if (value!.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
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
            if (state.isAuthenticated) {
              context.go(AppRoutes.maintenances);
            } else if (state.hasError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Ocurrió un error'),
                  backgroundColor: const Color(0xFFEF4444),
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
                    Text(
                      'Comencemos',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inicia sesión o crea una cuenta para gestionar tus vehículos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
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
                        label: 'Ingresa tu contraseña',
                        textInputAction: TextInputAction.done,
                        focusNode: _passwordFocusNode,
                        onFieldSubmitted: _handleEmailLogin,
                      ),
                      const SizedBox(height: 24),

                      // Sign in button
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
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: isLoading ? null : _handleEmailLogin,
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
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Text(
                                            'Ingresar',
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
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Sign up section
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: '¿No tienes cuenta? ',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => context.push(AppRoutes.signup),
                            child: const Text(
                              'Crear una',
                              style: TextStyle(
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
                const SizedBox(height: 48),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 1, color: Colors.grey[200]),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'O continúa con',
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
