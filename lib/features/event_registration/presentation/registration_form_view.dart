import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/features/event_registration/presentation/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/registration_form_content.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

class RegistrationFormView extends StatelessWidget {
  final EventModel event;
  const RegistrationFormView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationFormCubit>();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: FormBuilder(
          key: cubit.formKey,
          child: RegistrationFormContent(event: event),
        ),
      ),
    );
  }
}
