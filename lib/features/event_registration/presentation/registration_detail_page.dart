import 'package:flutter/material.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_bottom_bar.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_emergency_card.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_header.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_info_row.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_section_card.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
      appBar: AppAppBar(title: context.l10n.registration_requestDetailsTitle),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RegistrationDetailHeader(registration: registration),
            if (!isOwner)
              ContactPopupMenuButton(
                phone: registration.phone,
                contactLabel: context.l10n.registration_contactLabel,
                callLabel: context.l10n.registration_callLabel,
                whatsappLabel: context.l10n.registration_whatsappLabel,
                alignment: Alignment.center,
              ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  RegistrationDetailSectionCard(
                    icon: Icons.person_outline,
                    title: context.l10n.registration_sectionPersonalInfo,
                    initiallyExpanded: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RegistrationDetailInfoRow(
                          label: context.l10n.registration_fullNameLabel,
                          value: registration.fullName,
                          showDivider: false,
                        ),
                        RegistrationDetailInfoRow(
                          label: context.l10n.registration_identificationIdLabel,
                          value: registration.identificationNumber,
                        ),
                        RegistrationDetailInfoRow(
                          label: context.l10n.registration_phone,
                          value: registration.phone,
                        ),
                        RegistrationDetailInfoRow(
                          label: context.l10n.registration_email,
                          value: registration.email,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  RegistrationDetailSectionCard(
                    icon: Icons.medical_services_outlined,
                    title: context.l10n.registration_sectionHealthSafety,
                    initiallyExpanded: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RegistrationDetailInfoRow(
                          label: context.l10n.registration_epsOrInsuranceLabel,
                          value:
                              registration.medicalInsurance != null &&
                                  registration.medicalInsurance!.isNotEmpty
                              ? '${registration.eps} / ${registration.medicalInsurance}'
                              : registration.eps,
                          showDivider: false,
                        ),
                        RegistrationDetailInfoRow(
                          label: context.l10n.registration_bloodTypeLabel,
                          value: registration.bloodType.label,
                          valueColor: context.colorScheme.error,
                        ),
                        SizedBox(height: 8),
                        Text(
                          context.l10n.registration_emergencyContact,
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
                  SizedBox(height: 12),
                  RegistrationDetailSectionCard(
                    icon: Icons.two_wheeler_outlined,
                    title: context.l10n.registration_sectionVehicleDetails,
                    initiallyExpanded: true,
                    child: _VehicleDetailContent(registration: registration),
                  ),
                  SizedBox(height: 100),
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
            color: context.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.two_wheeler_outlined,
            size: 32,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.registration_motorcycleLabel.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 4),
              Text(
                vehicleModel,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${context.l10n.registration_plateLabel}: ',
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
                      color: context.appColors.licensePlateTagBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      registration.licensePlate,
                      style: textTheme.labelMedium?.copyWith(
                        color: context.appColors.licensePlateTagText,
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
