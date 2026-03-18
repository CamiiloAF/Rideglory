import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/registration_form_view.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/params.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
      child: _RegistrationFormScaffold(event: event),
    );
  }
}

class _RegistrationFormScaffold extends StatelessWidget {
  final EventModel event;
  const _RegistrationFormScaffold({required this.event});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationFormCubit>();
    final isEditing = cubit.isEditing;

    return Scaffold(
      appBar: AppAppBar(
        title: isEditing
            ? context.l10n.registration_editRegistration
            : context.l10n.registration_registrationPageTitle,
      ),
      body: BlocListener<RegistrationFormCubit,
          ResultState<EventRegistrationModel>>(
        listener: (context, state) {
          state.whenOrNull(
            data: (registration) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEditing
                        ? context.l10n.registration_registrationUpdatedSuccess
                        : context.l10n.registration_registrationSentSuccess,
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
