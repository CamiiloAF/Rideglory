import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/events/presentation/attendees/attendee_action_confirmation.dart';
import 'package:rideglory/features/events/presentation/detail/cubit/event_detail_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_participant_row.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// "Inscritos" section showing real attendee count + preview rows + view-all link.
///
/// Reads from `EventDetailCubit.state.attendeesResult` which is populated by
/// `loadAttendees(eventId)` (calls `/events/{id}/registrations`, not `/me`).
/// Owner of the event is excluded from the count and preview.
class EventDetailParticipantsSection extends StatelessWidget {
  const EventDetailParticipantsSection({super.key, required this.event});

  final EventModel event;

  static const int _previewLimit = 3;

  void _openAttendees(BuildContext context) {
    context.pushNamed(AppRoutes.eventAttendees, extra: event);
  }

  void _openRegistrationDetail(
    BuildContext context,
    EventRegistrationModel registration,
  ) {
    final cubit = context.read<EventDetailCubit>();
    final registrationId = registration.id;
    context.pushNamed(
      AppRoutes.registrationDetail,
      extra: RegistrationDetailExtra(
        registration: registration,
        eventOwnerId: event.ownerId,
        onApprove: registrationId == null
            ? null
            : (detailContext) => AttendeeActionConfirmation.showApprove(
                detailContext,
                participantName: registration.fullName,
                onConfirm: () {
                  cubit.approveAttendee(registrationId);
                  if (detailContext.mounted) detailContext.pop();
                },
              ),
        onReject: registrationId == null
            ? null
            : (detailContext) => AttendeeActionConfirmation.showReject(
                detailContext,
                participantName: registration.fullName,
                onConfirm: () {
                  cubit.rejectAttendee(registrationId);
                  if (detailContext.mounted) detailContext.pop();
                },
              ),
        onRequestEdit: registrationId == null
            ? null
            : (detailContext) => AttendeeActionConfirmation.showRequestEdit(
                detailContext,
                participantName: registration.fullName,
                onConfirm: () {
                  cubit.setAttendeeReadyForEdit(registrationId);
                  if (detailContext.mounted) detailContext.pop();
                },
              ),
      ),
    );
  }

  List<EventRegistrationModel> _visible(
    List<EventRegistrationModel> registrations,
  ) => registrations.where((r) => r.userId != event.ownerId).toList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventDetailCubit, EventDetailState>(
      buildWhen: (prev, curr) => prev.attendeesResult != curr.attendeesResult,
      builder: (context, state) {
        final visible = state.attendeesResult.when(
          initial: () => const <EventRegistrationModel>[],
          loading: () => const <EventRegistrationModel>[],
          data: _visible,
          empty: () => const <EventRegistrationModel>[],
          error: (_) => const <EventRegistrationModel>[],
        );
        final countText = state.attendeesResult.when(
          initial: () => '…',
          loading: () => '…',
          data: (regs) => _visible(regs).length.toString(),
          empty: () => '0',
          error: (_) => '—',
        );
        final preview = visible.take(_previewLimit).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${context.l10n.event_registrationsTab} ($countText)',
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Space Grotesk',
                  ),
                ),
                state.attendeesResult.maybeWhen(
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
                  error: (_) => IconButton(
                    tooltip: context.l10n.retry,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    iconSize: 18,
                    color: AppColors.textOnDarkSecondary,
                    onPressed: () => context
                        .read<EventDetailCubit>()
                        .loadAttendees(event.id!),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  orElse: () => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openAttendees(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.event_viewAll,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Space Grotesk',
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.chevronRight,
                          color: AppColors.primary,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (preview.isNotEmpty) ...[
              Column(
                children: [
                  for (var i = 0; i < preview.length; i++) ...[
                    EventDetailParticipantRow(
                      registration: preview[i],
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(i == 0 ? 12 : 0),
                        bottom: Radius.circular(
                          i == preview.length - 1 ? 12 : 0,
                        ),
                      ),
                      onTap: () => _openRegistrationDetail(context, preview[i]),
                    ),
                    if (i != preview.length - 1) const SizedBox(height: 2),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openAttendees(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.event_viewAttendees,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
