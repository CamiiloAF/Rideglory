import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class FormSectionTitle extends StatelessWidget {
  const FormSectionTitle({super.key, required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: context.colorScheme.onSurface, size: 20),
          AppSpacing.hGapSm,
        ],
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.onSurface,
              ),
        ),
      ],
    );
  }
}
