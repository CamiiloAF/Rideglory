import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class SoatEmptyState extends StatelessWidget {
  const SoatEmptyState({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkBorderPrimary),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.textOnDarkTertiary,
                size: 40,
              ),
            ),
            AppSpacing.gapXxl,
            Text(
              context.l10n.soat_status_no_soat,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              context.l10n.soat_manual_note,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            AppSpacing.gapXxl,
            AppButton(
              label: context.l10n.soat_renew_btn,
              onPressed: () => context.pushNamed(
                AppRoutes.soatUpload,
                extra: vehicle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
