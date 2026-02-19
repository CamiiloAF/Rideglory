import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/theme/app_text_styles.dart';

/// Divider with centered text widget
class DividerWithText extends StatelessWidget {
  final String text;

  const DividerWithText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(height: 1, color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(fontSize: 13),
          ),
        ),
        const Expanded(child: Divider(height: 1, color: AppColors.border)),
      ],
    );
  }
}
