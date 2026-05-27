import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/model/registration_with_event.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_type_filter_chips.dart';
import 'package:rideglory/features/events/presentation/list/widgets/events_filter_button.dart';
import 'package:rideglory/features/events/presentation/list/widgets/events_search_bar.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Main content view for the events list screen.
/// Matches Pencil page 0: search bar + filter btn, filter chips row, event cards.
class EventsDataView extends StatelessWidget {
  const EventsDataView({super.key, required this.events});

  final List<EventModel> events;

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthCubit>().state.currentUser?.id;
    final myRegistrationsState = context.watch<MyRegistrationsCubit>().state;
    final registeredEventIds = _buildRegisteredIds(myRegistrationsState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search + Filter btn ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: EventsSearchBar(
                  onChanged: (query) =>
                      context.read<EventsCubit>().updateSearchQuery(query),
                ),
              ),
              const SizedBox(width: 10),
              EventsFilterButton(onTap: () => _showFilters(context)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Filter chips ────────────────────────────────────────────────
        const EventTypeFilterChips(),
        const SizedBox(height: 16),

        // ── Event list ──────────────────────────────────────────────────
        Expanded(
          child: events.isEmpty
              ? const NoSearchResultsEmptyWidget()
              : RefreshIndicator(
                  onRefresh: () => context.read<EventsCubit>().fetchEvents(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      final event = events[i];
                      final isOwner = event.ownerId == currentUserId;
                      final isRegistered = event.id != null &&
                          registeredEventIds.contains(event.id);
                      return EventCard(
                        key: event.id != null
                            ? ValueKey(event.id)
                            : ObjectKey(event),
                        event: event,
                        isOwner: isOwner,
                        isRegistered: isRegistered,
                        onStartEvent: isOwner
                            ? () =>
                                context.read<EventsCubit>().startEvent(event)
                            : null,
                        onTap: () => _navigateToDetail(context, event),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Set<String> _buildRegisteredIds(
      ResultState<List<RegistrationWithEvent>> state) {
    final ids = <String>{};
    if (state is Data<List<RegistrationWithEvent>>) {
      for (final item in state.data) {
        final status = item.registration.status;
        final isActive = status == RegistrationStatus.pending ||
            status == RegistrationStatus.approved ||
            status == RegistrationStatus.readyForEdit;
        if (isActive && item.registration.eventId.isNotEmpty) {
          ids.add(item.registration.eventId);
        }
      }
    }
    return ids;
  }

  Future<void> _navigateToDetail(
      BuildContext context, EventModel event) async {
    final result = await context.pushNamed<dynamic>(
      AppRoutes.eventDetail,
      extra: event,
    );
    if (context.mounted) {
      if (result is EventModel) {
        context.read<EventsCubit>().updateEvent(result);
      } else if (result == true && event.id != null) {
        context.read<EventsCubit>().removeEvent(event.id!);
      }
    }
  }

  Future<void> _showFilters(BuildContext context) async {
    await EventFiltersBottomSheet.show(context: context);
  }
}
