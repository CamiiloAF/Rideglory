import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/cubit/event_detail_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// "Inscritos" section showing real attendee count + view-all link.
///
/// Reads from `EventDetailCubit.state.attendeesResult` which is populated by
/// `loadAttendees(eventId)` (calls `/events/{id}/registrations`, not `/me`).
/// Owner of the event is excluded from the count.
class EventDetailParticipantsSection extends StatelessWidget {
  const EventDetailParticipantsSection({super.key, required this.event});

  final EventModel event;

  void _openAttendees(BuildContext context) {
    context.pushNamed(AppRoutes.eventAttendees, extra: event);
  }

  int _countVisible(List dynRegistrations) {
    // Excluye al owner del conteo visible.
    return dynRegistrations.where((r) => r.userId != event.ownerId).length;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventDetailCubit, EventDetailState>(
      buildWhen: (prev, curr) => prev.attendeesResult != curr.attendeesResult,
      builder: (context, state) {
        final countText = state.attendeesResult.when(
          initial: () => '…',
          loading: () => '…',
          data: (regs) => _countVisible(regs).toString(),
          empty: () => '0',
          error: (_) => '—',
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.event_registrationsTab,
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.19),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$countText ${context.l10n.event_participants}',
                    style: const TextStyle(
                      color: AppColors.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                  const Icon(Icons.chevron_right,
                      color: AppColors.primary, size: 14),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
