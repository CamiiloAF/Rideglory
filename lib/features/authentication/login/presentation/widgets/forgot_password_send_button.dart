import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';

class ForgotPasswordSendButton extends StatelessWidget {
  const ForgotPasswordSendButton({super.key, required this.onSend});

  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return AppButton(
          label: context.l10n.auth_recovery_send,
          onPressed: onSend,
          isLoading: state.isLoading,
        );
      },
    );
  }
}
