import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class LoginHeading extends StatelessWidget {
  const LoginHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.auth_loginTitle,
          textAlign: TextAlign.center,
          style: context.textTheme.displayMedium?.copyWith(
            color: context.colorScheme.onSurface,
          ),
        ),
        AppSpacing.gapXs,
        Text(
          context.l10n.auth_loginSubtitleStitch,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
