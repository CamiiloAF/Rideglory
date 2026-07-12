import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/features/events/domain/use_cases/get_events_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_events_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/presentation/tracking/live_tracking_session_holder.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/events_page_view.dart';

class EventsPage extends StatelessWidget {
  final bool showMyEvents;
  const EventsPage({super.key, this.showMyEvents = false});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          context.goNamed(
            AppRoutes.home,
          ); // Intentional: shell-tab navigation resets stack to prevent back-stack accumulation in StatefulShellRoute
        }
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) {
              final finishedStream =
                  getIt<LiveTrackingSessionHolder>().onEventFinished;
              return (showMyEvents
                    ? EventsCubit.myEvents(
                        getIt<GetMyEventsUseCase>(),
                        getIt<UpdateEventUseCase>(),
                        getIt<AnalyticsService>(),
                        eventFinishedStream: finishedStream,
                      )
                    : EventsCubit(
                        getIt<GetEventsUseCase>(),
                        getIt<UpdateEventUseCase>(),
                        getIt<AnalyticsService>(),
                        eventFinishedStream: finishedStream,
                      ))
                ..fetchEvents();
            },
          ),
          BlocProvider(create: (_) => getIt<EventDeleteCubit>()),
        ],
        child: EventsPageView(showMyEvents: showMyEvents),
      ),
    );
  }
}
