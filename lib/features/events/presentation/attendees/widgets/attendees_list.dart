import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendee_pending_request_card.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendee_processed_item.dart';
import 'package:rideglory/features/events/presentation/attendees/attendee_action_confirmation.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class AttendeesList extends StatelessWidget {
  final List<EventRegistrationModel> registrations;
  final EventModel event;

  const AttendeesList({
    super.key,
    required this.registrations,
    required this.event,
  });

  static bool _isPending(EventRegistrationModel r) =>
      r.status == RegistrationStatus.pending ||
      r.status == RegistrationStatus.readyForEdit;

  static bool _isProcessed(EventRegistrationModel r) =>
      r.status == RegistrationStatus.approved ||
      r.status == RegistrationStatus.rejected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final pending = registrations.where(_isPending).toList();
    final processed = registrations.where(_isProcessed).toList();

    return RefreshIndicator(
      onRefresh: () => context.read<AttendeesCubit>().fetchAttendees(event.id!),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          if (pending.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  EventStrings.newRequestsSection,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    EventStrings.pendingCountBadge(pending.length),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...pending.map(
              (registration) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AttendeePendingRequestCard(
                  registration: registration,
                  onTap: () => context.pushNamed(
                    AppRoutes.registrationDetail,
                    extra: RegistrationDetailExtra(
                      registration: registration,
                      onApprove: registration.id != null
                          ? (detailContext) =>
                                AttendeeActionConfirmation.showApprove(
                                  detailContext,
                                  firstName: registration.firstName,
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
                      onReject: registration.id != null
                          ? (detailContext) =>
                                AttendeeActionConfirmation.showReject(
                                  detailContext,
                                  firstName: registration.firstName,
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
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              Text(
                EventStrings.processedSection,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: processed.isEmpty ? null : () {},
                child: Text(
                  EventStrings.allWithCount(processed.length),
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (processed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                EventStrings.noAttendees,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...processed.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AttendeeProcessedItem(
                  registration: r,
                  onTap: () => context.pushNamed(
                    AppRoutes.registrationDetail,
                    extra: RegistrationDetailExtra(registration: r),
                  ),
                  onOptionsPressed: () {},
                ),
              ),
            ),
        ],
      ),
    );
  }
}
