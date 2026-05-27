import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleFormAddMoreDocSlot extends StatelessWidget {
  const VehicleFormAddMoreDocSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorderPrimary),
            ),
            child: const Icon(
              Icons.add,
              size: 20,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.vehicle_form_add_doc_title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textOnDarkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.vehicle_form_add_doc_subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textOnDarkTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textOnDarkTertiary,
          ),
        ],
      ),
    );
  }
}
