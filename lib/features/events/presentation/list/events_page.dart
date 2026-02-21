import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/events/domain/use_cases/get_events_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_events_use_case.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/events_page_view.dart';

class EventsPage extends StatelessWidget {
  final bool showMyEvents;
  const EventsPage({super.key, this.showMyEvents = false});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => showMyEvents
              ? EventsCubit.myEvents(getIt<GetMyEventsUseCase>())
              : EventsCubit(getIt<GetEventsUseCase>())
            ..fetchEvents(),
        ),
        BlocProvider(create: (_) => getIt<EventDeleteCubit>()),
      ],
      child: EventsPageView(showMyEvents: showMyEvents),
    );
  }
}