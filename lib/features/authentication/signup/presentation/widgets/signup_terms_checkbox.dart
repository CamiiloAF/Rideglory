import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupTermsCheckbox extends StatelessWidget {
  const SignupTermsCheckbox({
    super.key,
    required this.accepted,
    required this.onChanged,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  static const _termsUrl = 'https://camiiloaf.github.io/Rideglory/terms-and-conditions.html';
  static const _privacyUrl = 'https://camiiloaf.github.io/Rideglory/privacy-policy.html';

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = context.textTheme.bodySmall?.copyWith(
      color: AppColors.textOnDarkSecondary,
      height: 1.4,
    );
    final linkStyle = baseStyle?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );

    return GestureDetector(
      onTap: () => onChanged(!accepted),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: accepted,
              onChanged: (value) => onChanged(value ?? false),
              activeColor: AppColors.primary,
              side: const BorderSide(color: AppColors.darkBorderPrimary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: baseStyle,
                children: [
                  TextSpan(text: context.l10n.auth_termsPrefix),
                  TextSpan(
                    text: context.l10n.auth_termsOf,
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()..onTap = () => _open(_termsUrl),
                  ),
                  TextSpan(text: context.l10n.auth_termsAnd),
                  TextSpan(
                    text: context.l10n.auth_termsConditions,
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()..onTap = () => _open(_termsUrl),
                  ),
                  TextSpan(text: context.l10n.auth_termsAnd2),
                  TextSpan(
                    text: context.l10n.auth_termsPrivacy,
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()..onTap = () => _open(_privacyUrl),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
