import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class LoginDivider extends StatelessWidget {
  const LoginDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(height: 1, color: AppColors.darkBorderPrimary),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.l10n.auth_orContinueWithStitch,
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ),
        const Expanded(
          child: Divider(height: 1, color: AppColors.darkBorderPrimary),
        ),
      ],
    );
  }
}
