import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_difficulty_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_multi_brand_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_price_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart';

/// Step 2: Difficulty + Event type + Multi-brand + Max participants + Price.
class EventFormStep2 extends StatelessWidget {
  const EventFormStep2({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventFormDifficultySection(),
                AppSpacing.gapXxl,
                EventFormEventTypeSection(),
                AppSpacing.gapXxl,
                EventFormMultiBrandSection(),
                AppSpacing.gapXxl,
                EventFormMaxParticipantsSection(),
                AppSpacing.gapXxl,
                EventFormPriceSection(),
              ],
            ),
          ),
        ),
        EventStepNavBar(),
      ],
    );
  }
}
