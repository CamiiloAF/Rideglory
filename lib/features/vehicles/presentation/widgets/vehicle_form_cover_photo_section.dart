import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_form_empty_cover_state.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_form_image_preview.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_form_outline_button.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

class VehicleFormCoverPhotoSection extends StatelessWidget {
  const VehicleFormCoverPhotoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FormImageCubit, ResultState<FormImageData>>(
      builder: (context, imageState) {
        final imageData = imageState.whenOrNull(data: (data) => data);
        final hasImage = imageData?.displayImageUrl != null;
        final isLocal = imageData?.hasLocalImage == true;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: hasImage
                  ? null
                  : () => context.read<FormImageCubit>().pickImageFromGallery(),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasImage
                        ? AppColors.darkBorderLight
                        : AppColors.darkBorderPrimary,
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: hasImage
                    ? VehicleFormImagePreview(
                        imageData: imageData!,
                        isLocal: isLocal,
                        onClear: () =>
                            context.read<FormImageCubit>().clearLocalImage(),
                      )
                    : const VehicleFormEmptyCoverState(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: VehicleFormOutlineButton(
                    icon: Icons.upload_outlined,
                    label: context.l10n.vehicle_form_upload_btn,
                    onTap: () =>
                        context.read<FormImageCubit>().pickImageFromGallery(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VehicleFormOutlineButton(
                    icon: Icons.camera_alt_outlined,
                    label: context.l10n.vehicle_form_take_photo_btn,
                    onTap: () =>
                        context.read<FormImageCubit>().pickImageFromCamera(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
