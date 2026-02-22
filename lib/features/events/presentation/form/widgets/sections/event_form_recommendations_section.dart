import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/presentation/form/widgets/form_section_title.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

class EventFormRecommendationsSection extends StatelessWidget {
  const EventFormRecommendationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionTitle(title: EventStrings.recommendations),
        const SizedBox(height: 12),
        AppTextField(
          name: EventFormFields.recommendations,
          labelText: EventStrings.recommendationsLabel,
          hintText: EventStrings.recommendationsHint,
          prefixIcon: Icons.tips_and_updates_outlined,
          maxLines: 8,
          minLines: 4,
        ),
      ],
    );
  }
}
