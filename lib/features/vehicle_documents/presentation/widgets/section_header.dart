import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Generic section header with icon, title, and optional trailing widget.
class DocumentSectionHeader extends StatelessWidget {
  const DocumentSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textOnDarkTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textOnDarkTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
