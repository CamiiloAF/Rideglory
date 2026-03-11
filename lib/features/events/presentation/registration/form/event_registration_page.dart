import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/registration/form/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/events/presentation/registration/form/widgets/registration_form_view.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';

class EventRegistrationPage extends StatelessWidget {
  final EventModel event;
  final EventRegistrationModel? existingRegistration;

  const EventRegistrationPage({
    super.key,
    required this.event,
    this.existingRegistration,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RegistrationFormCubit>()
        ..initialize(
          eventId: event.id!,
          eventName: event.name,
          existingRegistration: existingRegistration,
        ),
      child: _RegistrationFormView(event: event),
    );
  }
}

class _RegistrationFormView extends StatelessWidget {
  final EventModel event;
  const _RegistrationFormView({required this.event});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationFormCubit>();
    final isEditing = cubit.isEditing;

    return Scaffold(
      appBar: AppAppBar(
        title: isEditing
            ? RegistrationStrings.editRegistration
            : RegistrationStrings.registrationForm,
      ),
      body:
          BlocListener<
            RegistrationFormCubit,
            ResultState<EventRegistrationModel>
          >(
            listener: (context, state) {
              state.whenOrNull(
                data: (registration) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? RegistrationStrings.registrationUpdatedSuccess
                            : RegistrationStrings.registrationSentSuccess,
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.pop(registration);
                },
                error: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );
            },
            child: RegistrationFormView(event: event),
          ),
    );
  }
}
