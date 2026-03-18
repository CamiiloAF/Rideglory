import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/authentication/constants/auth_strings.dart';

class SignupTermsText extends StatelessWidget {
  const SignupTermsText({super.key});

  @override
  Widget build(BuildContext context) {
    final baseStyle = context.textTheme.bodySmall?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    final accentStyle = baseStyle?.copyWith(
      color: context.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    return RichText(
      text: TextSpan(
        text: AuthStrings.termsPrefix,
        style: baseStyle,
        children: [
          TextSpan(text: AuthStrings.termsOf, style: accentStyle),
          TextSpan(text: AuthStrings.termsAnd, style: baseStyle),
          TextSpan(text: AuthStrings.termsConditions, style: accentStyle),
          TextSpan(text: AuthStrings.termsAnd2, style: baseStyle),
          TextSpan(text: AuthStrings.termsPrivacy, style: accentStyle),
          TextSpan(text: AuthStrings.termsSuffix, style: baseStyle),
        ],
      ),
    );
  }
}
