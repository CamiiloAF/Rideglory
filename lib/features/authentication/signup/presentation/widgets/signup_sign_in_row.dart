import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class SignupSignInRow extends StatelessWidget {
  const SignupSignInRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.l10n.auth_already_have_account,
          style: context.textTheme.bodySmall?.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            if (context.canPop()) context.pop();
          },
          child: Text(
            context.l10n.auth_sign_in_link,
            style: context.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
