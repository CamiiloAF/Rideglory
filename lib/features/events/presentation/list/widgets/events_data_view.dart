import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/model/registration_with_event.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_filter_chip.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart';
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
                child: _SearchBar(
                  onChanged: (query) =>
                      context.read<EventsCubit>().updateSearchQuery(query),
                ),
              ),
              const SizedBox(width: 10),
              _FilterButton(onTap: () => _showFilters(context)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Filter chips ────────────────────────────────────────────────
        const _EventTypeFilterChips(),
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

  Set<String> _buildRegisteredIds(ResultState<List<RegistrationWithEvent>> state) {
    final ids = <String>{};
    if (state is Data<List<RegistrationWithEvent>>) {
      for (final item in state.data) {
        final status = item.registration.status;
        final isActive =
            status == RegistrationStatus.pending ||
            status == RegistrationStatus.approved ||
            status == RegistrationStatus.readyForEdit;
        if (isActive && item.registration.eventId.isNotEmpty) {
          ids.add(item.registration.eventId);
        }
      }
    }
    return ids;
  }

  Future<void> _navigateToDetail(BuildContext context, EventModel event) async {
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

// ──────────────────────────────────────────────────────────────────────────────
// Private widgets
// ──────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(
          color: AppColors.textOnDarkPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: context.l10n.event_searchEvents,
          hintStyle: const TextStyle(
            color: AppColors.textOnDarkTertiary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textOnDarkTertiary,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          isDense: true,
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.tune_rounded,
          color: AppColors.darkBgPrimary,
          size: 18,
        ),
      ),
    );
  }
}

class _EventTypeFilterChips extends StatelessWidget {
  const _EventTypeFilterChips();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<EventsCubit>();
    final selectedTypes = cubit.filters.types;

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          EventFilterChip(
            label: context.l10n.event_filterAll,
            isSelected: selectedTypes.isEmpty,
            onTap: () =>
                cubit.updateFilters(cubit.filters.copyWith(types: {})),
          ),
          const SizedBox(width: 8),
          ...EventType.values.map((type) {
            final isSelected = selectedTypes.contains(type);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: EventFilterChip(
                label: type.label,
                isSelected: isSelected,
                onTap: () {
                  final newTypes = Set<EventType>.from(selectedTypes);
                  if (isSelected) {
                    newTypes.remove(type);
                  } else {
                    newTypes.add(type);
                  }
                  cubit.updateFilters(cubit.filters.copyWith(types: newTypes));
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
