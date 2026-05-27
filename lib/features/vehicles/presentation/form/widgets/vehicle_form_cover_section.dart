import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

class VehicleFormCoverSection extends StatelessWidget {
  const VehicleFormCoverSection({super.key});

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
                  : () =>
                      context.read<FormImageCubit>().pickImageFromGallery(),
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
                    ? _VehicleCoverImagePreview(
                        imageData: imageData!,
                        isLocal: isLocal,
                        onClear: () =>
                            context.read<FormImageCubit>().clearLocalImage(),
                      )
                    : const _VehicleCoverEmptyState(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _VehicleCoverOutlineButton(
                    icon: Icons.upload_outlined,
                    label: context.l10n.vehicle_form_upload_btn,
                    onTap: () =>
                        context.read<FormImageCubit>().pickImageFromGallery(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VehicleCoverOutlineButton(
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

class _VehicleCoverEmptyState extends StatelessWidget {
  const _VehicleCoverEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.camera_alt_outlined,
          size: 32,
          color: AppColors.textOnDarkTertiary,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.vehicle_form_cover_title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnDarkSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.vehicle_form_cover_subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textOnDarkTertiary,
          ),
        ),
      ],
    );
  }
}

class _VehicleCoverImagePreview extends StatelessWidget {
  const _VehicleCoverImagePreview({
    required this.imageData,
    required this.isLocal,
    required this.onClear,
  });

  final FormImageData imageData;
  final bool isLocal;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        isLocal
            ? Image.file(File(imageData.localImagePath!), fit: BoxFit.cover)
            : Image.network(imageData.remoteImageUrl!, fit: BoxFit.cover),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.darkBgPrimary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: AppColors.textOnDarkPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleCoverOutlineButton extends StatelessWidget {
  const _VehicleCoverOutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.darkTertiary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.textOnDarkSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
