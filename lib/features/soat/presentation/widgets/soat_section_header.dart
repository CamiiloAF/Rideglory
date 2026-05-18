import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class SoatSectionHeader extends StatelessWidget {
  const SoatSectionHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textOnDarkTertiary,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}
