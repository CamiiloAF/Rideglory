import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class LoginForgotPasswordLink extends StatelessWidget {
  const LoginForgotPasswordLink({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTextButton(
      label: context.l10n.auth_forgotPassword,
      onPressed: () {
        // TODO: implement forgot password navigation
      },
      visualDensity: VisualDensity.compact,
    );
  }
}
