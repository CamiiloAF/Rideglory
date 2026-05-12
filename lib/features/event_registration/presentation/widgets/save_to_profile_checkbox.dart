import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';
import 'package:rideglory/features/event_registration/presentation/cubit/registration_form_cubit.dart';

class SaveToProfileCheckbox extends StatelessWidget {
  const SaveToProfileCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationFormCubit>();
    return AppCheckbox(
      name: RegistrationFormFields.saveToProfile,
      title: context.l10n.registration_saveToProfile,
      initialValue: cubit.saveToProfile,
      onChanged: cubit.toggleSaveToProfile,
    );
  }
}
