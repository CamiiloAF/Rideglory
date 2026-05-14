import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class RegistrationFormSectionCard extends StatelessWidget {
  const RegistrationFormSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) ...[
                AppSpacing.hGapSm,
                trailing!,
              ],
            ],
          ),
          AppSpacing.gapLg,
          child,
        ],
      ),
    );
  }
}
