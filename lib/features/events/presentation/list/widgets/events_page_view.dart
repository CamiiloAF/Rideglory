import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/events_state_widgets.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Events list screen — matches Pencil page 0.
/// Header: "Explorar Eventos" title.
/// Body: search bar, type filter chips, event cards.
/// FAB: orange pill button "Crear evento" — bottom-right.
class EventsPageView extends StatelessWidget {
  const EventsPageView({super.key, this.showMyEvents = false});

  final bool showMyEvents;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      floatingActionButton: _CreateEventFab(showMyEvents: showMyEvents),
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<EventDeleteCubit, ResultState<String>>(
              listener: (context, state) {
                state.whenOrNull(
                  data: (eventId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.event_eventDeletedSuccess),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.read<EventsCubit>().removeEvent(eventId);
                  },
                  error: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(context.l10n.errorMessage(error.message)),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                );
              },
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      showMyEvents
                          ? context.l10n.event_myEvents
                          : context.l10n.event_events,
                      style: const TextStyle(
                        color: AppColors.textOnDarkPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────────────
              Expanded(
                child: BlocBuilder<EventsCubit, ResultState<List<EventModel>>>(
                  builder: (context, state) {
                    final cubit = context.read<EventsCubit>();
                    return state.maybeWhen(
                      loading: () => const PageLoadingStateWidget(),
                      error: (error) => PageErrorStateWidget(
                        title: context.l10n.event_errorLoadingEvents,
                        message: error.message,
                        onRetry: () => cubit.fetchEvents(),
                        onRefresh: () => cubit.fetchEvents(),
                      ),
                      empty: () {
                        final hasFilters = cubit.filters.hasFilters;
                        return EmptyStateWidget(
                          icon: Icons.search_off_outlined,
                          title: hasFilters
                              ? context.l10n.event_noResultsFiltered
                              : context.l10n.event_noEvents,
                          description: hasFilters
                              ? null
                              : context.l10n.event_noEventsDescription,
                          actionButtonText: hasFilters
                              ? context.l10n.event_clearFilters
                              : context.l10n.event_createEvent,
                          onActionPressed: hasFilters
                              ? cubit.clearFilters
                              : () => _navigateToCreate(context),
                          onRefresh: () => cubit.fetchEvents(),
                        );
                      },
                      data: (events) => EventsDataView(events: events),
                      orElse: () => const PageLoadingStateWidget(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToCreate(BuildContext context) async {
    final result =
        await context.pushNamed<EventModel?>(AppRoutes.createEvent);
    if (result != null && context.mounted) {
      context.read<EventsCubit>().addEvent(result);
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _CreateEventFab extends StatelessWidget {
  const _CreateEventFab({required this.showMyEvents});

  final bool showMyEvents;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result =
            await context.pushNamed<EventModel?>(AppRoutes.createEvent);
        if (result != null && context.mounted) {
          context.read<EventsCubit>().addEvent(result);
        }
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: AppColors.darkBgPrimary, size: 18),
          ],
        ),
      ),
    );
  }
}
