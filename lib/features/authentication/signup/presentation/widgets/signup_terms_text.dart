import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
        text: context.l10n.auth_termsPrefix,
        style: baseStyle,
        children: [
          TextSpan(text: context.l10n.auth_termsOf, style: accentStyle),
          TextSpan(text: context.l10n.auth_termsAnd, style: baseStyle),
          TextSpan(text: context.l10n.auth_termsConditions, style: accentStyle),
          TextSpan(text: context.l10n.auth_termsAnd2, style: baseStyle),
          TextSpan(text: context.l10n.auth_termsPrivacy, style: accentStyle),
          TextSpan(text: context.l10n.auth_termsSuffix, style: baseStyle),
        ],
      ),
    );
  }
}
