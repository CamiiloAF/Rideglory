import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/get_my_registrations_use_case.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_view.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_by_id_use_case.dart';

class MyRegistrationsPage extends StatelessWidget {
  const MyRegistrationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyRegistrationsCubit(
        getIt<GetMyRegistrationsUseCase>(),
        getIt<CancelEventRegistrationUseCase>(),
        getIt<GetEventByIdUseCase>(),
      )..fetchMyRegistrations(),
      child: const MyRegistrationsView(),
    );
  }
}
