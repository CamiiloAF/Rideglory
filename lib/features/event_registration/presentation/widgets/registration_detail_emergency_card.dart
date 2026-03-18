import 'package:flutter/material.dart';
import 'package:rideglory/shared/helpers/url_launcher_helper.dart';
import 'package:rideglory/design_system/design_system.dart';

class RegistrationDetailEmergencyCard extends StatelessWidget {
  const RegistrationDetailEmergencyCard({
    super.key,
    required this.contactName,
    required this.contactPhone,
    this.showPhoneButton = true,
  });

  final String contactName;
  final String contactPhone;
   final bool showPhoneButton;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.outlineVariant),
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
                AppSpacing.gapXxs,
                Text(
                  contactPhone,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (showPhoneButton)
            Material(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => UrlLauncherHelper.openPhone(contactPhone),
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.call_rounded, color: context.appColors.success),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
