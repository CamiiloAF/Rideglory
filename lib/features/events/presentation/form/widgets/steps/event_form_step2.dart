import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_difficulty_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_max_participants_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_multi_brand_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_price_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/step_title.dart';

/// Step 2: Difficulty + Event type + Multi-brand + Max participants + Price.
class EventFormStep2 extends StatelessWidget {
  const EventFormStep2({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepTitle(
                  title: context.l10n.event_step2_title,
                  subtitle: context.l10n.event_step2_subtitle,
                ),
                AppSpacing.gapXxl,
                const EventFormDifficultySection(),
                AppSpacing.gapXxl,
                const EventFormEventTypeSection(),
                AppSpacing.gapXxl,
                const EventFormMultiBrandSection(),
                AppSpacing.gapXxl,
                const EventFormMaxParticipantsSection(),
                AppSpacing.gapXxl,
                const EventFormPriceSection(),
              ],
            ),
          ),
        ),
        const EventStepNavBar(),
      ],
    );
  }
}
