import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_type_filter_chips.dart';
import 'package:rideglory/shared/widgets/no_search_results_empty_widget.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/form/app_search_bar.dart';

class EventsDataView extends StatelessWidget {
  final List<EventModel> events;

  const EventsDataView({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final currentUserId = getIt<AuthService>().currentUser?.uid;

    return Column(
      children: [
        // Search bar with filter button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  hintText: EventStrings.searchEvents,
                  onSearchChanged: (query) =>
                      context.read<EventsCubit>().updateSearchQuery(query),
                  padding: EdgeInsets.zero,
                  darkMode: true,
                ),
              ),
              const SizedBox(width: 12),
              // Filter button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showFilters(context),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.tune, color: Colors.grey[400], size: 24),
                        // Active filters indicator
                        if (context.watch<EventsCubit>().filters.hasFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
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
        const EventTypeFilterChips(),
        const SizedBox(height: 8),
        events.isEmpty
            ? NoSearchResultsEmptyWidget()
            : Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<EventsCubit>().fetchEvents(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    itemBuilder: (_, i) {
                      final event = events[i];
                      final isOwner = event.ownerId == currentUserId;
                      return EventCard(
                        event: event,
                        isOwner: isOwner,
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
