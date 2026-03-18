import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';

class LoginHeading extends StatelessWidget {
  const LoginHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AuthStrings.loginTitle,
          textAlign: TextAlign.center,
          style: context.textTheme.displayMedium?.copyWith(
            color: context.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 6),
        Text(
          AuthStrings.loginSubtitleStitch,
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
