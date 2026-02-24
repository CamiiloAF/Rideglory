import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/presentation/form/widgets/form_section_title.dart';
import 'package:rideglory/shared/widgets/form/app_rich_text_editor.dart';

class EventFormRecommendationsSection extends StatelessWidget {
  const EventFormRecommendationsSection({super.key, this.initialValue});

  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    final form = FormBuilder.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionTitle(title: EventStrings.recommendations),
        const SizedBox(height: 12),
        AppRichTextEditor(
          name: EventFormFields.recommendations,
          labelText: EventStrings.recommendationsLabel,
          hintText: EventStrings.recommendationsHint,
          initialValue: initialValue,
          minLines: 8,
          onChanged: (value) {
            form?.fields[EventFormFields.recommendations]?.didChange(value);
          },
        ),
      ],
    );
  }
}
