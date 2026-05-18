import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class SoatManualOptionCard extends StatelessWidget {
  const SoatManualOptionCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.darkBgPrimary,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 28,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.vehicle_soat_option_manual_title,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.vehicle_soat_option_manual_desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.darkBgPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.darkBorderPrimary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.vehicle_soat_option_manual_cta,
                    style: const TextStyle(
                      color: AppColors.textOnDarkPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.textOnDarkPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
