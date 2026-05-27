import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class ProfileFormSectionHeader extends StatelessWidget {
  const ProfileFormSectionHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnDarkSecondary,
        letterSpacing: 1.5,
      ),
    );
  }
}
