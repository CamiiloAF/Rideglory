import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/shared/helpers/url_launcher_helper.dart';

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
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  contactName,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contactPhone,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () => UrlLauncherHelper.openPhone(contactPhone),
              borderRadius: BorderRadius.circular(24),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.call_rounded, color: AppColors.success),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
