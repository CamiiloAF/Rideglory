import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_by_id_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_registration_for_event_use_case.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/cubit/event_detail_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/event_detail_view.dart';
import 'package:rideglory/features/events/presentation/detail/params.dart';

class EventDetailPage extends StatelessWidget {
  final EventDetailPageParams params;

  const EventDetailPage({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        if (!params.isFromEventDetailByIdPage)
          BlocProvider(
            create: (_) => EventDetailCubit(
              getIt<GetMyRegistrationForEventUseCase>(),
              getIt<CancelEventRegistrationUseCase>(),
              getIt<GetEventByIdUseCase>(),
            )..loadMyRegistration(params.event.id!),
          ),
        BlocProvider(create: (_) => getIt<EventDeleteCubit>()),
      ],
      child: BlocListener<EventDetailCubit, EventDetailState>(
        listener: (context, state) {
          state.registrationResult.when(
            initial: () {},
            loading: () {},
            data: (registration) {
              if (params.onRegistrationChanged != null && registration != null) {
                params.onRegistrationChanged!(registration);
              }
            },
            empty: () {},
            error: (_) {},
          );
        },
        child: EventDetailView(
          event: params.event,
          isFromEventDetailByIdPage: params.isFromEventDetailByIdPage,
        ),
      ),
    );
  }
}
