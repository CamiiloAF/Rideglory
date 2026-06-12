import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_basic_info_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_date_time_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/cover_empty.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/cover_picker_sheet.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/cover_preview_wrapper.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

/// Step 1: Cover + basic info + date/time.
class EventFormStep1 extends StatelessWidget {
  const EventFormStep1({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EventFormCubit>();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover
                BlocBuilder<FormImageCubit, ResultState<FormImageData>>(
                  builder: (context, imageState) {
                    final imageData =
                        imageState.whenOrNull(data: (data) => data);
                    final hasLocalImage = imageData?.hasLocalImage == true;

                    if (hasLocalImage ||
                        imageData?.displayImageUrl?.isNotEmpty == true) {
                      return CoverPreviewWrapper(
                        imageUrl: hasLocalImage
                            ? null
                            : imageData?.displayImageUrl,
                        localImagePath:
                            hasLocalImage ? imageData?.displayImageUrl : null,
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
                // Basic info
                AppSpacing.gapXxl,
                EventFormBasicInfoSection(
                  isEditing: cubit.isEditing,
                  descriptionInitialValue: cubit.editingEvent?.description,
                ),
                // Date & time
                AppSpacing.gapXxl,
                const EventFormDateTimeSection(),
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
