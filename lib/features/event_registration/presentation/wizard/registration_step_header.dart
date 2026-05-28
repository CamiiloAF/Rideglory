import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Header for a wizard step: an accent icon badge alongside a title and a
/// supporting subtitle, matching the Pencil `sectionHeader` design.
class RegistrationStepHeader extends StatelessWidget {
  const RegistrationStepHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySubtle,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textOnDarkPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppSpacing.gapXxs,
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
