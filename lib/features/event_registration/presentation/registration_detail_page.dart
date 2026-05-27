import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_bottom_bar.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_emergency_card.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_header.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_info_row.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_section_card.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class RegistrationDetailPage extends StatelessWidget {
  const RegistrationDetailPage({super.key, required this.params});

  final RegistrationDetailExtra params;

  @override
  Widget build(BuildContext context) {
    final registration = params.registration;
    final currentUserId = context.watch<AuthCubit>().state.currentUser?.id;
    final isRegistrantViewer = registration.userId == currentUserId;

    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        title: Text(
          context.l10n.registration_requestDetailsTitle,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.darkBgPrimary,
        surfaceTintColor: Colors.transparent, // Intentional: remove Material3 surface tint
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RegistrationDetailHeader(registration: registration),
            if (!isRegistrantViewer)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: ContactPopupMenuButton(
                  phone: registration.phone,
                  contactLabel: context.l10n.registration_contactLabel,
                  callLabel: context.l10n.registration_callLabel,
                  whatsappLabel: context.l10n.registration_whatsappLabel,
                  alignment: Alignment.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  RegistrationDetailSectionCard(
                    icon: Icons.person_outline_rounded,
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
                  AppSpacing.gapMd,
                  RegistrationDetailSectionCard(
                    icon: Icons.medical_services_outlined,
                    title: context.l10n.registration_sectionHealthSafety,
                    initiallyExpanded: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RegistrationDetailInfoRow(
                          label: context.l10n.registration_epsOrInsuranceLabel,
                          value: registration.medicalInsurance != null &&
                                  registration.medicalInsurance!.isNotEmpty
                              ? '${registration.eps} / ${registration.medicalInsurance}'
                              : registration.eps,
                          showDivider: false,
                        ),
                        RegistrationDetailInfoRow(
                          label: context.l10n.registration_bloodTypeLabel,
                          value: registration.bloodType.label,
                          valueColor: AppColors.error,
                        ),
                        AppSpacing.gapSm,
                        Text(
                          context.l10n.registration_emergencyContact,
                          style: const TextStyle(
                            color: AppColors.textOnDarkSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        AppSpacing.gapXxs,
                        RegistrationDetailEmergencyCard(
                          contactName: registration.emergencyContactName,
                          contactPhone: registration.emergencyContactPhone,
                          showPhoneButton: !isRegistrantViewer,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapMd,
                  RegistrationDetailSectionCard(
                    icon: Icons.two_wheeler_outlined,
                    title: context.l10n.registration_sectionVehicleDetails,
                    initiallyExpanded: true,
                    child: _VehicleDetailContent(registration: registration),
                  ),
                  AppSpacing.gap100,
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
