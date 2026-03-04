import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';
import 'package:rideglory/shared/widgets/form/app_text_button.dart';

class LoginRegisterLink extends StatelessWidget {
  final VoidCallback onTap;

  const LoginRegisterLink({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AuthStrings.noAccountQuestion,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        AppTextButton(
          label: AuthStrings.registerFreeLink,
          onPressed: onTap,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
