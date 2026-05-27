import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
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

  void _onPressed(LoginAuthProvider provider, VoidCallback action) {
    setState(() => _loadingProvider = provider);
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
          const SizedBox(height: 12),
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
