import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/registration_form_view.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class RegistrationFormScaffold extends StatelessWidget {
  final EventModel event;

  const RegistrationFormScaffold({super.key, required this.event});

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
              context.read<MyRegistrationsCubit>().onChangeRegistration(
                registration,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEditing
                        ? context.l10n.registration_registrationUpdatedSuccess
                        : context.l10n.registration_registrationSentSuccess,
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
              context.pop(registration);
            },
            error: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error.message),
                  backgroundColor: AppColors.error,
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
