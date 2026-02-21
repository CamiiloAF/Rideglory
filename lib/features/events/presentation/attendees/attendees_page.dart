import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/approve_registration_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_registrations_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/reject_registration_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/set_registration_ready_for_edit_use_case.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendees_view.dart';

class AttendeesPage extends StatelessWidget {
  final EventModel event;

  const AttendeesPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AttendeesCubit(
        getIt<GetEventRegistrationsUseCase>(),
        getIt<ApproveRegistrationUseCase>(),
        getIt<RejectRegistrationUseCase>(),
        getIt<SetRegistrationReadyForEditUseCase>(),
      )..fetchAttendees(event.id!),
      child: AttendeesView(event: event),
    );
  }
}
