import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/events/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_registrations_use_case.dart';
import 'package:rideglory/features/events/presentation/registration/list/my_registrations_cubit.dart';
import 'package:rideglory/features/events/presentation/registration/list/widgets/my_registrations_view.dart';

class MyRegistrationsPage extends StatelessWidget {
  const MyRegistrationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyRegistrationsCubit(
        getIt<GetMyRegistrationsUseCase>(),
        getIt<CancelEventRegistrationUseCase>(),
      )..fetchMyRegistrations(),
      child: const MyRegistrationsView(),
    );
  }
}
