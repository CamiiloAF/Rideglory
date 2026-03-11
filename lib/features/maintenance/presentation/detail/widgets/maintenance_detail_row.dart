import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class MaintenanceDetailRow extends StatelessWidget {
  const MaintenanceDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.bodyMedium?.copyWith(color: Colors.grey[400]),
        ),
        Text(
          value,
          style: context.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
