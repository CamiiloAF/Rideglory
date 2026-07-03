import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_bottom_bar.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_data_card.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_data_row.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_rider_summary.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_status_banner.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class RegistrationDetailPage extends StatelessWidget {
  const RegistrationDetailPage({super.key, required this.params});

  final RegistrationDetailExtra params;

  @override
  Widget build(BuildContext context) {
    final registration = params.registration;
    final isRegistrantViewer = !params.isOrganizerView;

    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        title: Text(
          isRegistrantViewer
              ? context.l10n.registration_myRegistration
              : context.l10n.registration_requestDetailsTitle,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.darkBgPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isRegistrantViewer)
            RegistrationDetailRiderSummary(
              registration: registration,
              onTap: () => context.pushNamed(
                AppRoutes.riderProfile,
                extra: registration.userId,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isRegistrantViewer) ...[
                    RegistrationDetailStatusBanner(status: registration.status),
                    AppSpacing.gapLg,
                  ],
                  RegistrationDetailDataCard(
                    icon: Icons.person_outline_rounded,
                    iconColor: AppColors.primary,
                    iconBackgroundColor: AppColors.primarySubtle,
                    title: context.l10n.registration_personalData,
                    child: Column(
                      children: [
                        RegistrationDetailDataRow(
                          label: context.l10n.registration_rowName,
                          value: registration.fullName,
                        ),
                        RegistrationDetailDataRow(
                          label: context.l10n.registration_rowIdentification,
                          value: registration.identificationNumber,
                          showDivider: true,
                        ),
                        RegistrationDetailDataRow(
                          label: context.l10n.registration_rowBirthDate,
                          value: registration.birthDate.formattedDate,
                          showDivider: true,
                        ),
                        RegistrationDetailDataRow(
                          label: context.l10n.registration_rowPhone,
                          value: registration.phone,
                          showDivider: true,
                        ),
                        RegistrationDetailDataRow(
                          label: context.l10n.registration_rowEmail,
                          value: registration.email,
                          showDivider: true,
                        ),
                        RegistrationDetailDataRow(
                          label: context.l10n.registration_rowCity,
                          value: registration.residenceCity,
                          showDivider: true,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapLg,
                  RegistrationDetailDataCard(
                    icon: Icons.favorite_outline_rounded,
                    iconColor: AppColors.error,
                    iconBackgroundColor: AppColors.errorSubtle,
                    title: context.l10n.registration_medicalInfo,
                    child: Column(
                      children: [
                        RegistrationDetailDataRow(
                          label: context.l10n.registration_rowEps,
                          value: registration.eps,
                        ),
                        if (registration.medicalInsurance != null &&
                            registration.medicalInsurance!.isNotEmpty)
                          RegistrationDetailDataRow(
                            label:
                                context.l10n.registration_rowMedicalInsurance,
                            value: registration.medicalInsurance!,
                            showDivider: true,
                          ),
                        RegistrationDetailDataRow(
                          label: context.l10n.registration_rowBloodType,
                          value:
                              registration.bloodType?.label ??
                              registration.bloodTypeRaw ??
                              context.l10n.notAvailable,
                          showDivider: true,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapLg,
                  RegistrationDetailDataCard(
                    icon: Icons.phone_in_talk_outlined,
                    iconColor: AppColors.error,
                    iconBackgroundColor: AppColors.errorSubtle,
                    title: context.l10n.registration_emergencyContactTitle,
                    child: Column(
                      children: [
                        RegistrationDetailDataRow(
                          label: context.l10n.registration_rowContactName,
                          value: registration.emergencyContactName,
                        ),
                        RegistrationDetailDataRow(
                          label: context.l10n.registration_rowPhone,
                          value: registration.emergencyContactPhone,
                          showDivider: true,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapLg,
                  RegistrationDetailDataCard(
                    icon: Icons.two_wheeler_outlined,
                    iconColor: AppColors.primary,
                    iconBackgroundColor: AppColors.primarySubtle,
                    title: context.l10n.registration_participationData,
                    child: Column(
                      children: [
                        RegistrationDetailDataRow(
                          label: context.l10n.registration_rowVehicle,
                          value: _vehicleLabel(context, registration),
                        ),
                        // El dominio de inscripción no modela tipos de
                        // participante (piloto/acompañante): toda inscripción
                        // es piloto principal, por eso el valor es fijo.
                        RegistrationDetailDataRow(
                          label: context.l10n.registration_rowParticipationType,
                          value: context
                              .l10n
                              .registration_participationRiderPrincipal,
                          showDivider: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: RegistrationDetailBottomBar(params: params),
    );
  }

  String _vehicleLabel(
    BuildContext context,
    EventRegistrationModel registration,
  ) {
    final summary = registration.vehicleSummary;
    if (summary != null && summary.displayName.isNotEmpty) {
      final plate = summary.licensePlate;
      if (plate != null && plate.isNotEmpty) {
        return '${summary.displayName} · $plate';
      }
      return summary.displayName;
    }
    return context.l10n.notAvailable;
  }
}
