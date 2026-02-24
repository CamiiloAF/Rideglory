import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/form_section_title.dart';
import 'package:rideglory/shared/widgets/form/app_chips_input.dart';
import 'package:rideglory/shared/widgets/form/app_dropdown.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

class EventFormDetailsSection extends StatelessWidget {
  const EventFormDetailsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionTitle(title: EventStrings.eventDetails),
        const SizedBox(height: 12),
        AppDropdown<EventDifficulty>(
          name: EventFormFields.difficulty,
          labelText: EventStrings.difficulty,
          isRequired: true,
          prefixIcon: const Icon(Icons.local_fire_department_outlined),
          validator: FormBuilderValidators.required(
            errorText: EventStrings.difficultyRequired,
          ),
          items: EventDifficulty.values
              .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
              .toList(),
        ),
        const SizedBox(height: 16),
        AppDropdown<EventType>(
          name: EventFormFields.eventType,
          labelText: EventStrings.eventType,
          isRequired: true,
          prefixIcon: const Icon(Icons.category_outlined),
          validator: FormBuilderValidators.required(
            errorText: EventStrings.eventTypeRequired,
          ),
          items: EventType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
        ),
        const SizedBox(height: 16),
        AppChipsInput(
          name: EventFormFields.allowedBrands,
          labelText: EventStrings.allowedBrands,
          hintText: EventStrings.allowedBrandsHint,
          helperText: EventStrings.allowedBrandsHelper,
          prefixIcon: Icons.shield_outlined,
          initialValue: context.read<EventFormCubit>().state.maybeWhen(
            editing: (event) => event.allowedBrands,
            orElse: () => [],
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          name: EventFormFields.price,
          labelText: EventStrings.price,
          prefixIcon: Icons.attach_money,
          keyboardType: TextInputType.number,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.numeric(
              errorText: EventStrings.invalidPrice,
              checkNullOrEmpty: false,
            ),
          ]),
        ),
      ],
    );
  }
}
