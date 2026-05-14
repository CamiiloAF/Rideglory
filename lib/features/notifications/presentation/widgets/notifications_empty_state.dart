import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class NotificationsEmptyState extends StatelessWidget {
  const NotificationsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              excludeSemantics: true,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.darkBorderPrimary),
                ),
                child: const Icon(
                  Icons.notifications_none_outlined,
                  color: AppColors.textOnDarkTertiary,
                  size: 40,
                ),
              ),
            ),
            AppSpacing.gapXxl,
            Text(
              context.l10n.notification_emptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              context.l10n.notification_emptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
