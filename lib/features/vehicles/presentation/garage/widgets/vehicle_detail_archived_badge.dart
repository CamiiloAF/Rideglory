import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleDetailArchivedBadge extends StatelessWidget {
  const VehicleDetailArchivedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.archive_outlined,
            size: 11,
            color: AppColors.textOnDarkSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.vehicle_archivedVehicle,
            style: const TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
