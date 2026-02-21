import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_filters_bottom_sheet.dart';
import 'package:rideglory/features/events/presentation/list/widgets/events_data_view.dart';
import 'package:rideglory/features/events/presentation/list/widgets/events_state_widgets.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/shared/widgets/app_drawer.dart';

class EventsPageView extends StatelessWidget {
  final bool showMyEvents;
  const EventsPageView({super.key, this.showMyEvents = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: showMyEvents ? EventStrings.myEvents : EventStrings.events,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (context.watch<EventsCubit>().filters.hasFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilters(context),
          ),
          IconButton(
            icon: const Icon(Icons.my_library_books_outlined),
            tooltip: EventStrings.myEvents,
            onPressed: () => context.pushNamed(AppRoutes.myEvents),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.events),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreate(context),
        child: const Icon(Icons.add),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<EventDeleteCubit, ResultState<Nothing>>(
            listener: (context, state) {
              state.whenOrNull(
                data: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(EventStrings.eventDeletedSuccess),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.read<EventsCubit>().fetchEvents();
                },
                error: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.errorMessage(error.message)),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );
            },
          ),
        ],
        child: BlocBuilder<EventsCubit, ResultState<List<EventModel>>>(
          builder: (context, state) => state.maybeWhen(
            loading: () => const EventsLoadingWidget(),
            error: (error) => EventsErrorWidget(
              message: error.message,
              onRefresh: () => context.read<EventsCubit>().fetchEvents(),
            ),
            empty: () => EventsEmptyWidget(
              onRefresh: () => context.read<EventsCubit>().fetchEvents(),
              onCreatePressed: () => _navigateToCreate(context),
            ),
            data: (events) => EventsDataView(events: events),
            orElse: () => const EventsLoadingWidget(),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToCreate(BuildContext context) async {
    final result = await context.pushNamed<bool?>(AppRoutes.createEvent);
    if (result == true && context.mounted) {
      context.read<EventsCubit>().fetchEvents();
    }
  }

  Future<void> _showFilters(BuildContext context) async {
    final cubit = context.read<EventsCubit>();
    final result = await EventFiltersBottomSheet.show(
      context: context,
      initialFilters: cubit.filters,
    );
    if (result != null && context.mounted) {
      cubit.updateFilters(result);
    }
  }
}
