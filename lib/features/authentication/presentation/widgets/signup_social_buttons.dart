import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/presentation/widgets/social_login_button.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';

class SignupSocialButtons extends StatelessWidget {
  final VoidCallback onEmailModeToggle;

  const SignupSocialButtons({super.key, required this.onEmailModeToggle});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state.isLoading;
        return Column(
          children: [
            // Social buttons
            SocialLoginButton(
              type: SocialLoginType.email,
              isLoading: isLoading,
              onPressed: onEmailModeToggle,
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
            const SizedBox(height: 32),

            // Divider with "Already have account?" text
            Row(
              children: [
                Expanded(child: Container(height: 1, color: Colors.grey[200])),
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
                Expanded(child: Container(height: 1, color: Colors.grey[200])),
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
                        child: const Text(
                          AuthStrings.signInLink,
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
          ],
        );
      },
    );
  }
}
