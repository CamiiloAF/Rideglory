import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

/// Header widget for signup view with title and subtitle
class SignupHeader extends StatelessWidget {
  final bool isEmailMode;
  final String emailModeTitle;
  final String emailModeSubtitle;
  final String socialModeTitle;
  final String socialModeSubtitle;

  const SignupHeader({
    super.key,
    required this.isEmailMode,
    required this.emailModeTitle,
    required this.emailModeSubtitle,
    required this.socialModeTitle,
    required this.socialModeSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEmailMode ? emailModeTitle : socialModeTitle,
          style: context.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          isEmailMode ? emailModeSubtitle : socialModeSubtitle,
          style: context.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
