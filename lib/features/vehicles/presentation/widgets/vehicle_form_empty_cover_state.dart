import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleFormEmptyCoverState extends StatelessWidget {
  const VehicleFormEmptyCoverState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt_outlined, size: 32, color: AppColors.textOnDarkTertiary),
        const SizedBox(height: 8),
        Text(
          context.l10n.vehicle_form_cover_title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnDarkSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.vehicle_form_cover_subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textOnDarkTertiary,
          ),
        ),
      ],
    );
  }
}
