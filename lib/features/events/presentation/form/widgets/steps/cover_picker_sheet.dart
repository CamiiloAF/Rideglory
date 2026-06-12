import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

/// Bottom sheet for picking an event cover image.
///
/// Only offers gallery upload — no AI generation button.
/// Opens via [showModalBottomSheet] from Step 1.
class CoverPickerSheet extends StatelessWidget {
  const CoverPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkBgSecondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorderPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.event_cover_picker_title,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnDarkPrimary,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: context.l10n.event_cover_picker_gallery,
              onPressed: () {
                Navigator.of(context).pop();
                context.read<FormImageCubit>().pickImageFromGallery();
              },
              icon: Icons.photo_library_outlined,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
