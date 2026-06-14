import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_date_time_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_difficulty_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_event_type_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/cover_empty.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/cover_picker_sheet.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/cover_preview_wrapper.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/step_title.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

/// Step 1: Portada + nombre del evento + fecha y hora.
///
/// Design spec (Pencil AybHb):
/// - PORTADA: label + upload card
/// - INFORMACIÓN BÁSICA: label + campo nombre
/// - FECHA Y HORA: label + toggle varios días + date card
class EventFormStep1 extends StatelessWidget {
  const EventFormStep1({super.key});

  static const _sectionLabelStyle = TextStyle(
    fontFamily: 'Space Grotesk',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: AppColors.textOnDarkTertiary,
  );

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
                  title: context.l10n.event_step1_title,
                  subtitle: context.l10n.event_step1_subtitle,
                ),
                const SizedBox(height: 20),
                Text(
                  context.l10n.event_coverSectionLabel,
                  style: _sectionLabelStyle,
                ),
                const SizedBox(height: 10),
                BlocBuilder<FormImageCubit, ResultState<FormImageData>>(
                  builder: (context, imageState) {
                    final imageData = imageState.whenOrNull(
                      data: (data) => data,
                    );
                    final hasLocalImage = imageData?.hasLocalImage == true;
                    if (hasLocalImage ||
                        imageData?.displayImageUrl?.isNotEmpty == true) {
                      return CoverPreviewWrapper(
                        imageUrl: hasLocalImage
                            ? null
                            : imageData?.displayImageUrl,
                        localImagePath: hasLocalImage
                            ? imageData?.displayImageUrl
                            : null,
                        onChangeTap: () => _openCoverPicker(context),
                        onRemoveTap: hasLocalImage
                            ? () => context
                                  .read<FormImageCubit>()
                                  .clearLocalImage()
                            : null,
                      );
                    }
                    return CoverEmpty(onTap: () => _openCoverPicker(context));
                  },
                ),
                AppSpacing.gapXxl,
                Text(
                  context.l10n.event_form_eventName,
                  style: _sectionLabelStyle,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  name: EventFormFields.name,
                  hintText: context.l10n.event_eventNameHint,
                  isRequired: true,
                  textInputAction: TextInputAction.done,
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
                AppSpacing.gapXxl,
                Text(
                  context.l10n.event_form_dateTimeSectionLabel,
                  style: _sectionLabelStyle,
                ),
                const SizedBox(height: 10),
                const EventFormDateTimeSection(),
                AppSpacing.gapXxl,
                const EventFormDifficultySection(),
                AppSpacing.gapXxl,
                const EventFormEventTypeSection(),
              ],
            ),
          ),
        ),
        const EventStepNavBar(),
      ],
    );
  }

  void _openCoverPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<FormImageCubit>(),
        child: const CoverPickerSheet(),
      ),
    );
  }
}
