import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeEmptyEventsCard extends StatelessWidget {
  const HomeEmptyEventsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.darkBgSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 26,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.home_emptyEventsTitle,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.home_emptyEventsSubtitle,
            style: const TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AppButton(
            label: context.l10n.home_emptyEventsCta,
            onPressed: () => context.go(AppRoutes.events),
          ),
        ],
      ),
    );
  }
}
