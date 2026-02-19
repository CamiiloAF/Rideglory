import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_text_styles.dart';

/// Text with clickable link widget used in authentication screens
class AuthTextWithLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onLinkTap;

  const AuthTextWithLink({
    super.key,
    required this.text,
    required this.linkText,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: AppTextStyles.bodyMedium.copyWith(fontSize: 15),
        children: [
          WidgetSpan(
            child: GestureDetector(
              onTap: onLinkTap,
              child: Text(
                linkText,
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: 15,
                  color: context.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
