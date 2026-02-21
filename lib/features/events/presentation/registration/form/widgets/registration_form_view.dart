import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/registration/form/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/events/presentation/registration/form/widgets/registration_form_content.dart';

class RegistrationFormView extends StatelessWidget {
  final EventModel event;
  const RegistrationFormView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationFormCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilder(
        key: cubit.formKey,
        child: RegistrationFormContent(event: event),
      ),
    );
  }
}
