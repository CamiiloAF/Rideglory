import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/event_registration/domain/model/registration_with_event.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_type_filter_chips.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventsDataView extends StatelessWidget {
  final List<EventModel> events;

  const EventsDataView({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthCubit>().state.currentUser?.id;
    final myRegistrationsState = context.watch<MyRegistrationsCubit>().state;
    final registeredEventIds = <String>{};
    if (myRegistrationsState is Data<List<RegistrationWithEvent>>) {
      final items = myRegistrationsState.data;
      for (final item in items) {
        final status = item.registration.status;
        final isActive =
            status == RegistrationStatus.pending ||
            status == RegistrationStatus.approved ||
            status == RegistrationStatus.readyForEdit;
        if (isActive) {
          registeredEventIds.add(item.registration.eventId);
        }
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  hintText: context.l10n.event_searchEvents,
                  onSearchChanged: (query) =>
                      context.read<EventsCubit>().updateSearchQuery(query),
                  padding: EdgeInsets.zero,
                  darkMode: true,
                ),
              ),
              AppSpacing.hGapMd,
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: context.colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showFilters(context),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: context.colorScheme.onPrimary,
                          size: 24,
                        ),
                        if (context.watch<EventsCubit>().filters.hasFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: context.colorScheme.onPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapSm,
        const EventTypeFilterChips(),
        AppSpacing.gapSm,
        events.isEmpty
            ? const NoSearchResultsEmptyWidget()
            : Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<EventsCubit>().fetchEvents(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
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
                            ? () => context.read<EventsCubit>().startEvent(event)
                            : null,
                        onTap: () async {
                          final result = await context.pushNamed<dynamic>(
                            AppRoutes.eventDetail,
                            extra: event,
                          );
                          if (context.mounted) {
                            if (result is EventModel) {
                              context.read<EventsCubit>().updateEvent(result);
                            } else if (result == true && event.id != null) {
                              context.read<EventsCubit>().removeEvent(
                                event.id!,
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
      ],
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    await EventFiltersBottomSheet.show(context: context);
  }
}
