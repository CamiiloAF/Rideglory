import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendee_pending_request_card.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendee_processed_item.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendees_section_header.dart';
import 'package:rideglory/features/events/presentation/attendees/attendee_action_confirmation.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class AttendeesList extends StatelessWidget {
  final List<EventRegistrationModel> registrations;
  final EventModel event;

  const AttendeesList({
    super.key,
    required this.registrations,
    required this.event,
  });

  static bool _isPending(EventRegistrationModel registration) =>
      registration.status == RegistrationStatus.pending ||
      registration.status == RegistrationStatus.readyForEdit;

  static bool _isProcessed(EventRegistrationModel registration) =>
      registration.status == RegistrationStatus.approved ||
      registration.status == RegistrationStatus.rejected ||
      registration.status == RegistrationStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    // Owner del evento nunca debe aparecer en ninguna lista de inscritos
    // (su "inscripción automática" no es relevante para gestión de asistentes).
    final visible = registrations
        .where((registration) => registration.userId != event.ownerId)
        .toList();
    final pending = visible.where(_isPending).toList();
    final processed = visible.where(_isProcessed).toList();
    // Un evento terminal (finalizado/cancelado) no permite cambiar el estado
    // de las inscripciones.
    final canManage = !event.hasEnded;

    return RefreshIndicator(
      onRefresh: () => context.read<AttendeesCubit>().fetchAttendees(
        event.id!,
        forceRefresh: true,
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          if (pending.isNotEmpty) ...[
            AttendeesSectionHeader(
              label: context.l10n.event_newRequestsSection,
              labelColor: AppColors.textOnDarkTertiary,
              count: pending.length,
              countBackgroundColor: AppColors.statusWarning,
              countTextColor: AppColors.darkBgPrimary,
            ),
            AppSpacing.gapMd,
            ...pending.map(
              (registration) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AttendeePendingRequestCard(
                  registration: registration,
                  canManage: canManage,
                  onTap: () => context.pushNamed(
                    AppRoutes.registrationDetail,
                    extra: RegistrationDetailExtra(
                      registration: registration,
                      eventOwnerId: event.ownerId,
                      isOrganizerView: true,
                      eventState: event.state,
                      eventSosTriggeredAt: event.sosTriggeredAt,
                      onApprove: registration.id != null && canManage
                          ? (detailContext) =>
                                AttendeeActionConfirmation.showApprove(
                                  detailContext,
                                  participantName: registration.fullName,
                                  onConfirm: () {
                                    context
                                        .read<AttendeesCubit>()
                                        .approveRegistration(registration.id!);
                                    if (detailContext.mounted) {
                                      detailContext.pop();
                                    }
                                  },
                                )
                          : null,
                      onReject: registration.id != null && canManage
                          ? (detailContext) =>
                                AttendeeActionConfirmation.showReject(
                                  detailContext,
                                  participantName: registration.fullName,
                                  onConfirm: () {
                                    context
                                        .read<AttendeesCubit>()
                                        .rejectRegistration(registration.id!);
                                    if (detailContext.mounted) {
                                      detailContext.pop();
                                    }
                                  },
                                )
                          : null,
                      onRequestEdit: registration.id != null && canManage
                          ? (detailContext) =>
                                AttendeeActionConfirmation.showRequestEdit(
                                  detailContext,
                                  participantName: registration.fullName,
                                  onConfirm: () {
                                    context
                                        .read<AttendeesCubit>()
                                        .setReadyForEdit(registration.id!);
                                    if (detailContext.mounted) {
                                      detailContext.pop();
                                    }
                                  },
                                )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            AppSpacing.gapXxl,
          ],
          // La sección "Ya procesados" solo aparece si tiene registros: sin
          // ellos no mostramos un vacío que sugiera erróneamente que no hay
          // ningún inscrito (la sección de nuevas solicitudes puede tener).
          if (processed.isNotEmpty) ...[
            AttendeesSectionHeader(
              label: context.l10n.event_processedSection,
              labelColor: AppColors.textOnDarkTertiary,
              count: processed.length,
              countBackgroundColor: AppColors.darkTertiary,
              countTextColor: AppColors.textOnDarkSecondary,
            ),
            AppSpacing.gapMd,
            ...processed.map(
              (registration) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AttendeeProcessedItem(
                  registration: registration,
                  onTap: () => context.pushNamed(
                    AppRoutes.registrationDetail,
                    extra: RegistrationDetailExtra(
                      registration: registration,
                      eventOwnerId: event.ownerId,
                      isOrganizerView: true,
                      eventState: event.state,
                      eventSosTriggeredAt: event.sosTriggeredAt,
                    ),
                  ),
                  onOptionsPressed: () {},
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
