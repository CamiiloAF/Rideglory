import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/events_state_widgets.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventsPageView extends StatelessWidget {
  final bool showMyEvents;
  const EventsPageView({super.key, this.showMyEvents = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
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
                        content: Text(context.l10n.errorMessage(error.message)),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                );
              },
            ),
          ],
          child: BlocBuilder<EventsCubit, ResultState<List<EventModel>>>(
            builder: (context, state) {
              final eventsCubit = context.read<EventsCubit>();
              return state.maybeWhen(
                loading: () => const PageLoadingStateWidget(),
                error: (error) => PageErrorStateWidget(
                  title: context.l10n.event_errorLoadingEvents,
                  message: error.message,
                  onRetry: () => eventsCubit.fetchEvents(),
                  onRefresh: () => eventsCubit.fetchEvents(),
                ),
                empty: () {
                  final hasActiveFilters =
                      eventsCubit.filters.hasFilters;
                  return EmptyStateWidget(
                    icon: Icons.search_off_outlined,
                    title: hasActiveFilters
                        ? context.l10n.event_noResultsFiltered
                        : context.l10n.event_noEvents,
                    description: hasActiveFilters
                        ? null
                        : context.l10n.event_noEventsDescription,
                    actionButtonText: hasActiveFilters
                        ? context.l10n.event_clearFilters
                        : context.l10n.event_createEvent,
                    onActionPressed: hasActiveFilters
                        ? eventsCubit.clearFilters
                        : () => _navigateToCreate(context),
                    onRefresh: () => eventsCubit.fetchEvents(),
                  );
                },
                data: (events) => EventsDataView(events: events),
                orElse: () => const PageLoadingStateWidget(),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToCreate(BuildContext context) async {
    final result = await context.pushNamed<EventModel?>(AppRoutes.createEvent);
    if (result != null && context.mounted) {
      context.read<EventsCubit>().addEvent(result);
    }
  }
}
