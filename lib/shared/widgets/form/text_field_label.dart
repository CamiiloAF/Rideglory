import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class TextFieldLabel extends StatelessWidget {
  final String labelText;
  final bool isRequired;

  const TextFieldLabel({
    super.key,
    required this.labelText,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary;
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: labelColor,
    );

    final child = !isRequired
        ? Text(labelText, style: labelStyle)
        : Text.rich(
            TextSpan(
              text: labelText,
              style: labelStyle,
              children: [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: colorScheme.error),
                ),
              ],
            ),
          );

    return Padding(padding: const EdgeInsets.only(bottom: 6), child: child);
  }
}
