import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_status_pill.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';
import 'package:rideglory/features/events/presentation/attendees/attendee_action_confirmation.dart';
import 'package:rideglory/features/events/presentation/shared/widgets/initials_avatar.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class AttendeePendingRequestCard extends StatelessWidget {
  final EventRegistrationModel registration;
  final VoidCallback? onTap;

  const AttendeePendingRequestCard({
    super.key,
    required this.registration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vehicleText =
        registration.vehicleSummary?.displayName.isNotEmpty == true
        ? registration.vehicleSummary!.displayName
        : context.l10n.notAvailable;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InitialsAvatar(
                      fullName: registration.fullName,
                      radius: 22,
                      backgroundColor: AppColors.primarySubtle,
                      textStyle: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            registration.fullName,
                            style: const TextStyle(
                              color: AppColors.textOnDarkPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AppSpacing.gapXxs,
                          Row(
                            children: [
                              const Icon(
                                Icons.two_wheeler_rounded,
                                size: 13,
                                color: AppColors.textOnDarkSecondary,
                              ),
                              AppSpacing.hGapXxs,
                              Expanded(
                                child: Text(
                                  vehicleText,
                                  style: const TextStyle(
                                    color: AppColors.textOnDarkSecondary,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    RegistrationStatusPill(status: registration.status),
                  ],
                ),
              ),
            ),
            // Regla READY_FOR_EDIT: mientras la inscripción esté en este estado
            // el organizador SOLO puede rechazar (no aprobar). En PENDING se
            // muestran ambas acciones.
            const Divider(height: 1, color: AppColors.darkBorderPrimary),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ApproveRejectBar(
                rejectLabel: context.l10n.event_rejectRegistration,
                approveLabel: context.l10n.event_approveRegistration,
                showApprove:
                    registration.status != RegistrationStatus.readyForEdit,
                onReject: () => AttendeeActionConfirmation.showReject(
                  context,
                  participantName: registration.fullName,
                  onConfirm: () => context
                      .read<AttendeesCubit>()
                      .rejectRegistration(registration.id!),
                ),
                onApprove: () => AttendeeActionConfirmation.showApprove(
                  context,
                  participantName: registration.fullName,
                  onConfirm: () => context
                      .read<AttendeesCubit>()
                      .approveRegistration(registration.id!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
