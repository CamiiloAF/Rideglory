import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_events_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/drafts/my_drafts_view.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';

class MyDraftsPage extends StatelessWidget {
  const MyDraftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => EventsCubit.myEvents(
            getIt<GetMyEventsUseCase>(),
            getIt<UpdateEventUseCase>(),
          )..fetchEvents(),
        ),
        BlocProvider(create: (_) => getIt<EventDeleteCubit>()),
      ],
      child: const MyDraftsView(),
    );
  }
}
