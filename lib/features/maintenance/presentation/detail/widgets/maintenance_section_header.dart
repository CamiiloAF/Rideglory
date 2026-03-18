import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class MaintenanceSectionHeader extends StatelessWidget {
  const MaintenanceSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 24),
        SizedBox(width: 8),
        Text(
          title,
          style: context.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
