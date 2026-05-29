import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleSelectorEmpty extends StatelessWidget {
  const VehicleSelectorEmpty({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.two_wheeler,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.registration_vehicleEmptyStateTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnDarkPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.registration_vehicleEmptyStateSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: context.l10n.registration_createVehicleCta,
              onPressed: onCreate,
              style: AppButtonStyle.filled,
              shape: AppButtonShape.pill,
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}
