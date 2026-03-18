import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_cover_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/form_section_title.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_date_time_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_difficulty_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_locations_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_multi_brand_section.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventFormContent extends StatelessWidget {
  const EventFormContent({super.key});

  Map<String, dynamic> _getInitialValues(EventFormCubit cubit) {
    if (!cubit.isEditing) {
      return {
        EventFormFields.difficulty: EventDifficulty.one,
        EventFormFields.eventType: EventType.offRoad,
        EventFormFields.isMultiDay: false,
        EventFormFields.dateRange: DateTimeRange(
          start: DateTime.now(),
          end: DateTime.now(),
        ),
        EventFormFields.meetingTime: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          7,
          0,
        ),
        EventFormFields.isMultiBrand: true,
        EventFormFields.allowedBrands: <String>[],
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
      EventFormFields.isMultiBrand: event.allowedBrands.isEmpty,
      EventFormFields.allowedBrands: event.allowedBrands,
      EventFormFields.price: event.price?.toString() ?? '',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<EventFormCubit, ResultState<EventModel>>(
              builder: (context, state) {
                final innerCubit = context.read<EventFormCubit>();
                return EventFormCoverSection(
                  imageUrl: innerCubit.hasLocalCoverImage
                      ? null
                      : innerCubit.displayCoverImageUrl,
                  localImagePath: innerCubit.hasLocalCoverImage
                      ? innerCubit.displayCoverImageUrl
                      : null,
                  onUploadTap: () =>
                      innerCubit.pickCoverImageFromGallery(context),
                  onClearTap: innerCubit.hasLocalCoverImage
                      ? innerCubit.clearCoverImage
                      : null,
                );
              },
            ),
            SizedBox(height: 24),
            EventFormBasicInfoSection(
              isEditing: cubit.isEditing,
              descriptionInitialValue: cubit.editingEvent?.description,
              onAiSuggest: () {
                // TODO: Implement AI suggestions
              },
            ),
            SizedBox(height: 24),
            const EventFormDateTimeSection(),
            SizedBox(height: 24),
            const EventFormDifficultySection(),
            SizedBox(height: 24),
            const FormSectionTitle(
              title: EventStrings.routeAndMap,
              icon: Icons.route_outlined,
            ),
            SizedBox(height: 16),
            const EventFormLocationsSection(),
            SizedBox(height: 24),
            const FormSectionTitle(
              title: EventStrings.eventType,
              icon: Icons.category_outlined,
            ),
            const EventFormEventTypeSection(),
            SizedBox(height: 24),
            const EventFormMultiBrandSection(),
            SizedBox(height: 24),
            AppTextField(
              name: EventFormFields.price,
              labelText: EventStrings.price,
              hintText: EventStrings.priceHint,
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
        ),
      ),
    );
  }
}
