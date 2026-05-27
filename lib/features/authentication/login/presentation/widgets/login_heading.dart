import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class LoginHeading extends StatelessWidget {
  const LoginHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.auth_welcome_title,
          style: context.textTheme.displaySmall?.copyWith(
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.auth_welcome_subtitle,
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      ],
    );
  }
}
