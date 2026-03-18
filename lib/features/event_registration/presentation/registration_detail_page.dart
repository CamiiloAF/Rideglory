import 'package:flutter/material.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/event_registration/constants/registration_strings.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_bottom_bar.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_emergency_card.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_header.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_info_row.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_section_card.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/shared/widgets/contact_popup_menu_button.dart';

class RegistrationDetailPage extends StatelessWidget {
  const RegistrationDetailPage({super.key, required this.params});

  final RegistrationDetailExtra params;

  @override
  Widget build(BuildContext context) {
    final registration = params.registration;
    final currentUserId = getIt<AuthService>().currentUser?.uid;
    final isOwner = registration.userId == currentUserId;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: const AppAppBar(title: RegistrationStrings.requestDetailsTitle),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RegistrationDetailHeader(registration: registration),
            if (!isOwner)
              ContactPopupMenuButton(
                phone: registration.phone,
                contactLabel: RegistrationStrings.contactLabel,
                callLabel: RegistrationStrings.callLabel,
                whatsappLabel: RegistrationStrings.whatsappLabel,
                alignment: Alignment.center,
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  RegistrationDetailSectionCard(
                    icon: Icons.person_outline,
                    title: RegistrationStrings.sectionPersonalInfo,
                    initiallyExpanded: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RegistrationDetailInfoRow(
                          label: RegistrationStrings.fullNameLabel,
                          value: registration.fullName,
                          showDivider: false,
                        ),
                        RegistrationDetailInfoRow(
                          label: RegistrationStrings.identificationIdLabel,
                          value: registration.identificationNumber,
                        ),
                        RegistrationDetailInfoRow(
                          label: RegistrationStrings.phone,
                          value: registration.phone,
                        ),
                        RegistrationDetailInfoRow(
                          label: RegistrationStrings.email,
                          value: registration.email,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  RegistrationDetailSectionCard(
                    icon: Icons.medical_services_outlined,
                    title: RegistrationStrings.sectionHealthSafety,
                    initiallyExpanded: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RegistrationDetailInfoRow(
                          label: RegistrationStrings.epsOrInsuranceLabel,
                          value:
                              registration.medicalInsurance != null &&
                                  registration.medicalInsurance!.isNotEmpty
                              ? '${registration.eps} / ${registration.medicalInsurance}'
                              : registration.eps,
                          showDivider: false,
                        ),
                        RegistrationDetailInfoRow(
                          label: RegistrationStrings.bloodTypeLabel,
                          value: registration.bloodType.label,
                          valueColor: AppColors.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          RegistrationStrings.emergencyContact,
                          style: context.textTheme.titleSmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        RegistrationDetailEmergencyCard(
                          contactName: registration.emergencyContactName,
                          contactPhone: registration.emergencyContactPhone,
                          showPhoneButton: !isOwner,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  RegistrationDetailSectionCard(
                    icon: Icons.two_wheeler_outlined,
                    title: RegistrationStrings.sectionVehicleDetails,
                    initiallyExpanded: true,
                    child: _VehicleDetailContent(registration: registration),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RegistrationDetailBottomBar(params: params),
    );
  }
}

class _VehicleDetailContent extends StatelessWidget {
  const _VehicleDetailContent({required this.registration});

  final EventRegistrationModel registration;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final vehicleModel =
        '${registration.vehicleBrand} ${registration.vehicleReference}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.two_wheeler_outlined,
            size: 32,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                RegistrationStrings.motorcycleLabel.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                vehicleModel,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${RegistrationStrings.plateLabel}: ',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.licensePlateTagBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      registration.licensePlate,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.licensePlateTagText,
                        fontWeight: FontWeight.w600,
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
