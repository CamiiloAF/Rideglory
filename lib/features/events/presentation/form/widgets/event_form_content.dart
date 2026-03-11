import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_section_card.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_date_time_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_details_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_locations_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_recommendations_section.dart';

class EventFormContent extends StatelessWidget {
  const EventFormContent({super.key});

  Map<String, dynamic> _getInitialValues(EventFormCubit cubit) {
    if (!cubit.isEditing) {
      return {
        EventFormFields.difficulty: EventDifficulty.one,
        EventFormFields.eventType: EventType.onRoad,
        EventFormFields.isMultiDay: false,
        EventFormFields.dateRange: DateTimeRange(
          start: DateTime.now(),
          end: DateTime.now(),
        ),
        EventFormFields.meetingTime: DateTime.now(),
      };
    }
    final event = cubit.editingEvent!;
    return {
      EventFormFields.name: event.name,
      EventFormFields.description: event.description,
      EventFormFields.city: event.city,
      EventFormFields.isMultiDay:
          event.endDate != null && event.endDate != event.startDate,
      EventFormFields.dateRange: DateTimeRange(
        start: event.startDate,
        end: event.endDate ?? event.startDate,
      ),
      EventFormFields.meetingTime: event.meetingTime,
      EventFormFields.difficulty: event.difficulty,
      EventFormFields.eventType: event.eventType,
      EventFormFields.meetingPoint: event.meetingPoint,
      EventFormFields.destination: event.destination,
      EventFormFields.allowedBrands: event.allowedBrands,
      EventFormFields.price: event.price?.toString() ?? '',
      EventFormFields.recommendations: event.recommendations ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EventFormCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: FormBuilder(
        key: cubit.formKey,
        initialValue: _getInitialValues(cubit),
        child: BlocBuilder<EventFormCubit, ResultState<EventModel>>(
          builder: (context, state) {
            final innerCubit = context.read<EventFormCubit>();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventFormSectionCard(
                  icon: Icons.info_outline,
                  title: EventStrings.basicInfo,
                  child: Column(
                    children: [
                      EventFormBasicInfoSection(
                        isEditing: innerCubit.isEditing,
                      ),
                      const SizedBox(height: 16),
                      const EventFormDateTimeSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const EventFormSectionCard(
                  icon: Icons.settings_outlined,
                  title: EventStrings.eventDetails,
                  child: EventFormDetailsSection(),
                ),
                const SizedBox(height: 16),
                const EventFormSectionCard(
                  icon: Icons.route_outlined,
                  title: EventStrings.locations,
                  child: EventFormLocationsSection(),
                ),
                const SizedBox(height: 16),
                EventFormSectionCard(
                  icon: Icons.tips_and_updates_outlined,
                  title: EventStrings.recommendations,
                  child: EventFormRecommendationsSection(
                    initialValue: innerCubit.editingEvent?.recommendations,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }
}
