import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class AppTextFieldLabel extends StatelessWidget {
  const AppTextFieldLabel({
    super.key,
    required this.labelText,
    required this.isRequired,
  });

  final String labelText;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            labelText,
            style: context.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (isRequired)
            Text(
              ' *',
              style: context.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.errorColor,
              ),
            ),
        ],
      ),
    );
  }
}
