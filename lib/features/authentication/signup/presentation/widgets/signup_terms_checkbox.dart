import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupTermsCheckbox extends StatefulWidget {
  const SignupTermsCheckbox({
    super.key,
    required this.accepted,
    required this.onChanged,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  State<SignupTermsCheckbox> createState() => _SignupTermsCheckboxState();
}

class _SignupTermsCheckboxState extends State<SignupTermsCheckbox> {
  static const _termsUrl = 'https://camiiloaf.github.io/Rideglory/web/terms-and-conditions.html';
  static const _privacyUrl = 'https://camiiloaf.github.io/Rideglory/web/privacy-policy.html';

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = () => _open(_termsUrl);
    _privacyRecognizer = TapGestureRecognizer()..onTap = () => _open(_privacyUrl);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => widget.onChanged(!widget.accepted),
          child: SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: widget.accepted,
              onChanged: (value) => widget.onChanged(value ?? false),
              activeColor: AppColors.primary,
              side: const BorderSide(color: AppColors.darkBorderPrimary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
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
                  text: context.l10n.auth_termsAndConditions,
                  style: linkStyle,
                  recognizer: _termsRecognizer,
                ),
                TextSpan(text: context.l10n.auth_termsAnd2),
                TextSpan(
                  text: context.l10n.auth_termsPrivacy,
                  style: linkStyle,
                  recognizer: _privacyRecognizer,
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
