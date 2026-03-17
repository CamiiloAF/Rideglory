import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class RegistrationDetailEmergencyCard extends StatelessWidget {
  const RegistrationDetailEmergencyCard({
    super.key,
    required this.contactName,
    required this.contactPhone,
  });

  final String contactName;
  final String contactPhone;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contactName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contactPhone,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.phone_outlined,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
