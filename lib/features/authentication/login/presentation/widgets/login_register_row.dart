import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class LoginRegisterRow extends StatelessWidget {
  const LoginRegisterRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.l10n.auth_no_account,
          style: context.textTheme.bodySmall?.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => context.pushNamed(AppRoutes.signup),
          child: Text(
            context.l10n.auth_register_link,
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
