import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/presentation/widgets/social_login_button.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

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
            AppSpacing.gapMd,
            SocialLoginButton(
              type: SocialLoginType.google,
              isLoading: isLoading,
              onPressed: () {
                context.read<AuthCubit>().signInWithGoogle();
              },
            ),
            AppSpacing.gapMd,
            SocialLoginButton(
              type: SocialLoginType.apple,
              isLoading: isLoading,
              onPressed: () {
                context.read<AuthCubit>().signInWithApple();
              },
            ),
            AppSpacing.gapXxxl,

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
            AppSpacing.gapXxl,

            // Sign in link
            Center(
              child: RichText(
                text: TextSpan(
                  text: '${context.l10n.auth_signIn} ',
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
                          context.l10n.auth_signInLink,
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
          ],
        );
      },
    );
  }
}
