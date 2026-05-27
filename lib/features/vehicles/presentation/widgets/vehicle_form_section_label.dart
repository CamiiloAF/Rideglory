import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleFormSectionLabel extends StatelessWidget {
  const VehicleFormSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnDarkTertiary,
        letterSpacing: 1.2,
      ),
    );
  }
}
