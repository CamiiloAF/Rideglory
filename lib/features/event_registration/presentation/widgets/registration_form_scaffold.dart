import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/presentation/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/registration_form_view.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class RegistrationFormScaffold extends StatelessWidget {
  final EventModel event;

  const RegistrationFormScaffold({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final isEditing = context.read<RegistrationFormCubit>().isEditing;

    return Scaffold(
      appBar: AppAppBar(
        title: isEditing
            ? context.l10n.registration_editRegistration
            : context.l10n.registration_registrationPageTitle,
      ),
      // El resultado del envío (éxito y error) se maneja en el flujo del waiver
      // sheet: el éxito cierra la página con confirmación y el error se muestra
      // inline dentro del sheet, evitando un SnackBar de error redundante.
      body: RegistrationFormView(event: event),
    );
  }
}
