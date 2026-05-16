import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/form_section_title.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_date_time_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_difficulty_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_locations_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_multi_brand_section.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/events/presentation/form/widgets/cover_preview_widget.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';
import 'package:rideglory/shared/widgets/form/form_image_section.dart';

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
            BlocBuilder<EventFormCubit, EventFormState>(
              buildWhen: (previous, current) =>
                  previous.coverGenerationResult !=
                  current.coverGenerationResult,
              builder: (context, formState) {
                return BlocBuilder<FormImageCubit, ResultState<FormImageData>>(
                  builder: (context, imageState) {
                    final imageData =
                        imageState.whenOrNull(data: (data) => data);

                    final hasLocalImage = imageData?.hasLocalImage == true;
                    final coverResult = formState.coverGenerationResult;

                    if (hasLocalImage || coverResult is Initial<String>) {
                      return FormImageSection(
                        imageUrl: hasLocalImage
                            ? null
                            : imageData?.displayImageUrl,
                        localImagePath: hasLocalImage
                            ? imageData?.displayImageUrl
                            : null,
                        onPickImage: () =>
                            context
                                .read<FormImageCubit>()
                                .pickImageFromGallery(),
                        onClearTap: hasLocalImage
                            ? context.read<FormImageCubit>().clearLocalImage
                            : null,
                        title: context.l10n.event_addEventCover,
                        hint: context.l10n.event_addEventCoverHint,
                        uploadButtonLabel: context.l10n.event_uploadImage,
                        showGenerateWithAI: true,
                        generateWithAILabel: context.l10n.event_generateWithAI,
                        onGenerateWithAITap: () => _triggerGenerate(context),
                      );
                    }

                    final generatedImageUrl = coverResult.whenOrNull(
                      data: (url) => url,
                    );
                    final isGenerating = coverResult is Loading<String>;

                    return CoverPreviewWidget(
                      coverGenerationResult: coverResult,
                      imageUrl: generatedImageUrl,
                      isGenerating: isGenerating,
                      onGenerateTap: () => _triggerGenerate(context),
                      onRegenerateTap: () => _triggerGenerate(context),
                      onUploadTap: () =>
                          context
                              .read<FormImageCubit>()
                              .pickImageFromGallery(),
                    );
                  },
                );
              },
            ),
            AppSpacing.gapXxl,
            EventFormBasicInfoSection(
              isEditing: cubit.isEditing,
              descriptionInitialValue: cubit.editingEvent?.description,
              onAiSuggest: () {
                InfoDialog.show(
                  context: context,
                  title: context.l10n.event_generateWithAI,
                  content: context.l10n.event_comingSoon,
                );
              },
            ),
            AppSpacing.gapXxl,
            const EventFormDateTimeSection(),
            AppSpacing.gapXxl,
            const EventFormDifficultySection(),
            AppSpacing.gapXxl,
            FormSectionTitle(
              title: context.l10n.event_routeAndMap,
              icon: Icons.route_outlined,
            ),
            AppSpacing.gapLg,
            const EventFormLocationsSection(),
            AppSpacing.gapXxl,
            FormSectionTitle(
              title: context.l10n.event_eventType,
              icon: Icons.category_outlined,
            ),
            const EventFormEventTypeSection(),
            AppSpacing.gapXxl,
            const EventFormMultiBrandSection(),
            AppSpacing.gapXxl,
            AppTextField(
              name: EventFormFields.price,
              labelText: context.l10n.event_price,
              hintText: context.l10n.event_priceHint,
              prefixText: '\$',
              keyboardType: TextInputType.number,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.numeric(
                  errorText: context.l10n.event_invalidPrice,
                  checkNullOrEmpty: false,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerGenerate(BuildContext context) {
    final cubit = context.read<EventFormCubit>();
    final formState = cubit.formKey.currentState?.value;
    cubit.generateCover(
      title: formState?[EventFormFields.name] as String? ?? '',
      eventType:
          (formState?[EventFormFields.eventType] as EventType?)?.name ?? '',
      city: formState?[EventFormFields.city] as String? ?? '',
    );
  }
}
