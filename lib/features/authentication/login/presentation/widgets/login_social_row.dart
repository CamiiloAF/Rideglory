import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/login/presentation/widgets/login_social_button.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class LoginSocialRow extends StatelessWidget {
  const LoginSocialRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state.isLoading;
        return Row(
          children: [
            Expanded(
              child: LoginSocialButton(
                label: context.l10n.auth_googleLabel,
                icon: Icons.g_mobiledata_rounded,
                onPressed: isLoading
                    ? null
                    : () => context.read<AuthCubit>().signInWithGoogle(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: LoginSocialButton(
                label: context.l10n.auth_appleLabel,
                icon: Icons.apple,
                onPressed: null, // TODO: implement Apple sign-in
              ),
            ),
          ],
        );
      },
    );
  }
}
