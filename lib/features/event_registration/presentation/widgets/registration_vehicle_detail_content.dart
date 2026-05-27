import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

class RegistrationVehicleDetailContent extends StatelessWidget {
  const RegistrationVehicleDetailContent({super.key, required this.registration});

  final EventRegistrationModel registration;

  @override
  Widget build(BuildContext context) {
    final vehicleModel =
        registration.vehicleSummary?.displayName.isNotEmpty == true
            ? registration.vehicleSummary!.displayName
            : context.l10n.notAvailable;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.darkTertiary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.two_wheeler_outlined,
            size: 28,
            color: AppColors.textOnDarkSecondary,
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.registration_motorcycleLabel.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textOnDarkTertiary,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              AppSpacing.gapXxs,
              Text(
                vehicleModel,
                style: const TextStyle(
                  color: AppColors.textOnDarkPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapXxs,
              Row(
                children: [
                  Text(
                    '${context.l10n.registration_plateLabel}: ',
                    style: const TextStyle(
                      color: AppColors.textOnDarkSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.licensePlateTagBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      registration.vehicleSummary?.licensePlate ??
                          context.l10n.notAvailable,
                      style: const TextStyle(
                        color: AppColors.licensePlateTagText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
