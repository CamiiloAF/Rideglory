import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/data/colombia_cities_data.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/shared/widgets/form/app_autocomplete_field.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

class EventFormBasicInfoSection extends StatelessWidget {
  const EventFormBasicInfoSection({super.key, this.isEditing = false});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          name: EventFormFields.name,
          labelText: EventStrings.eventName,
          isRequired: true,
          enabled: !isEditing,
          helperText: !isEditing
              ? EventStrings.eventNameCannotBeModified
              : null,
          prefixIcon: Icons.event,
          textInputAction: TextInputAction.next,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(
              errorText: EventStrings.nameRequired,
            ),
            FormBuilderValidators.minLength(
              3,
              errorText: EventStrings.minCharacters,
            ),
          ]),
        ),
        const SizedBox(height: 16),
        AppTextField(
          name: EventFormFields.description,
          labelText: EventStrings.eventDescription,
          isRequired: true,
          prefixIcon: Icons.description_outlined,
          maxLines: 3,
          minLines: 1,
          validator: FormBuilderValidators.required(
            errorText: EventStrings.descriptionRequired,
          ),
        ),
        const SizedBox(height: 16),
        AppAutocompleteField(
          name: EventFormFields.city,
          labelText: EventStrings.eventCity,
          isRequired: true,
          prefixIcon: Icons.location_city_outlined,
          hintText: 'Ej: Medellín, Pereira...',
          suggestions: ColombiaCitiesData.search,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return EventStrings.cityRequired;
            }
            return null;
          },
        ),
      ],
    );
  }
}
