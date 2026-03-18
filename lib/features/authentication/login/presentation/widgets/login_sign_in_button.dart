import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class LoginSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LoginSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return SizedBox(
          height: 50,
          child: AppButton(
            label: context.l10n.auth_signInButton,
            onPressed: onPressed,
            isLoading: state.isLoading,
          ),
        );
      },
    );
  }
}
