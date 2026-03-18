import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/shared/widgets/form/app_city_autocomplete.dart';
import 'package:rideglory/shared/widgets/form/app_rich_text_editor.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

class EventFormBasicInfoSection extends StatelessWidget {
  const EventFormBasicInfoSection({
    super.key,
    this.isEditing = false,
    this.descriptionInitialValue,
    this.onAiSuggest,
  });

  final bool isEditing;
  final String? descriptionInitialValue;
  final VoidCallback? onAiSuggest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          name: EventFormFields.name,
          labelText: EventStrings.eventName,
          hintText: EventStrings.eventNameHint,
          isRequired: true,
          readonly: isEditing,
          suffixIcon: !isEditing
              ? Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(
                      Icons.info_outline,
                      color: AppColors.darkInputIcon,
                    ),
                    onPressed: () {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      scaffoldMessenger.hideCurrentSnackBar();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text(EventStrings.eventNameCannotBeModified),
                          duration: Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                )
              : null,
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
        AppRichTextEditor(
          name: EventFormFields.description,
          labelText: EventStrings.descriptionAndRecommendations,
          hintText: EventStrings.descriptionHint,
          initialValue: descriptionInitialValue,
          isRequired: true,
          minLines: 8,
          onAiSuggest: onAiSuggest,
          onChanged: (value) {
            FormBuilder.of(
              context,
            )?.fields[EventFormFields.description]?.didChange(value);
          },
          validator: FormBuilderValidators.required(
            errorText: EventStrings.descriptionRequired,
          ),
        ),
        const SizedBox(height: 16),
        AppCityAutocomplete(
          name: EventFormFields.city,
          labelText: EventStrings.eventCity,
          hintText: EventStrings.eventCityHint,
          isRequired: true,
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
