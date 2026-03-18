import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
          labelText: context.l10n.event_eventName,
          hintText: context.l10n.event_eventNameHint,
          isRequired: true,
          readonly: isEditing,
          suffixIcon: !isEditing
              ? Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      color: context.appColors.inputIcon,
                    ),
                    onPressed: () {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      scaffoldMessenger.hideCurrentSnackBar();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.event_eventNameCannotBeModified),
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
              errorText: context.l10n.event_nameRequired,
            ),
            FormBuilderValidators.minLength(
              3,
              errorText: context.l10n.event_minCharacters,
            ),
          ]),
        ),
        AppSpacing.gapLg,
        AppRichTextEditor(
          name: EventFormFields.description,
          labelText: context.l10n.event_descriptionAndRecommendations,
          hintText: context.l10n.event_descriptionHint,
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
            errorText: context.l10n.event_descriptionRequired,
          ),
        ),
        AppSpacing.gapLg,
        AppCityAutocomplete(
          name: EventFormFields.city,
          labelText: context.l10n.event_eventCity,
          hintText: context.l10n.event_eventCityHint,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.l10n.event_cityRequired;
            }
            return null;
          },
        ),
      ],
    );
  }
}
