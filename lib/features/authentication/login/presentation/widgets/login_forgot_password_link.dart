import 'package:flutter/material.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';
import 'package:rideglory/shared/widgets/form/app_text_button.dart';

class LoginForgotPasswordLink extends StatelessWidget {
  const LoginForgotPasswordLink({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTextButton(
      label: AuthStrings.forgotPassword,
      onPressed: () {
        // TODO: implement forgot password navigation
      },
      visualDensity: VisualDensity.compact,
    );
  }
}
