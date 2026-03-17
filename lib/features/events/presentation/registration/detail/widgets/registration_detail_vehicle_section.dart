import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_info_row.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_license_plate_tag.dart';
import 'package:rideglory/features/events/presentation/registration/detail/widgets/registration_detail_section.dart';

class RegistrationDetailVehicleSection extends StatelessWidget {
  const RegistrationDetailVehicleSection({
    super.key,
    required this.registration,
  });

  final EventRegistrationModel registration;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brandModel =
        '${registration.vehicleBrand} ${registration.vehicleReference}';
    final hasVin = registration.vin != null;

    return RegistrationDetailSection(
      title: RegistrationStrings.vehicleRegistered,
      icon: Icons.two_wheeler_outlined,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                RegistrationStrings.brandModelLabel.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                brandModel,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ],
          ),
        ),
        RegistrationDetailInfoRow(
          RegistrationStrings.licensePlate,
          registration.licensePlate,
          valueWidget: RegistrationDetailLicensePlateTag(
            plate: registration.licensePlate,
          ),
        ),
        if (hasVin)
          RegistrationDetailInfoRow(
            RegistrationStrings.vin,
            registration.vin!,
          ),
      ],
    );
  }
}

