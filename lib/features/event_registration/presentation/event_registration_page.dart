import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/event_registration/presentation/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_form_scaffold.dart';
import 'package:rideglory/features/events/presentation/detail/params.dart';

class EventRegistrationPage extends StatelessWidget {
  const EventRegistrationPage({super.key, required this.params});

  final EventRegistrationParams params;

  @override
  Widget build(BuildContext context) {
    final event = params.event;
    return BlocProvider(
      create: (_) => getIt<RegistrationFormCubit>()
        ..initialize(
          eventId: event.id!,
          eventName: event.name,
          existingRegistration: params.registration,
        ),
      child: RegistrationFormScaffold(event: event),
    );
  }
}
