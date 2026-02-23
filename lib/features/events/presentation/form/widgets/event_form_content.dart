import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_date_time_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_details_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_locations_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_recommendations_section.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class EventFormContent extends StatelessWidget {
  const EventFormContent({super.key});

  Map<String, dynamic> _getInitialValues(EventFormCubit cubit) {
    return cubit.state.maybeWhen(
      editing: (event) => {
        EventFormFields.name: event.name,
        EventFormFields.description: event.description,
        EventFormFields.city: event.city,
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
      },
      orElse: () => {
        EventFormFields.difficulty: EventDifficulty.one,
        EventFormFields.eventType: EventType.onRoad,
        EventFormFields.dateRange: DateTimeRange(
          start: DateTime.now(),
          end: DateTime.now(),
        ),
        EventFormFields.meetingTime: DateTime.now(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EventFormCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilder(
        key: cubit.formKey,
        initialValue: _getInitialValues(cubit),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EventFormBasicInfoSection(),
            const SizedBox(height: 24),
            const EventFormDateTimeSection(),
            const SizedBox(height: 24),
            EventFormDetailsSection(),
            const SizedBox(height: 24),
            const EventFormLocationsSection(),
            const SizedBox(height: 24),
            EventFormRecommendationsSection(
              initialValue: cubit.state.maybeWhen(
                editing: (event) => event.recommendations,
                orElse: () => null,
              ),
            ),
            const SizedBox(height: 32),
            BlocBuilder<EventFormCubit, EventFormState>(
              builder: (context, state) {
                final isLoading = state.maybeWhen(
                  loading: () => true,
                  orElse: () => false,
                );
                final isEditing = state.maybeWhen(
                  editing: (_) => true,
                  orElse: () => false,
                );
                return AppButton(
                  label: isEditing
                      ? EventStrings.updateEvent
                      : EventStrings.saveEvent,
                  isLoading: isLoading,
                  icon: Icons.save_outlined,
                  onPressed: isLoading
                      ? null
                      : () {
                          final event = cubit.buildEventToSave();
                          if (event != null) cubit.saveEvent(event);
                        },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
