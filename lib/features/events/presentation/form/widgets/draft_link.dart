import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

class DraftLink extends StatelessWidget {
  const DraftLink({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onSaveDraft(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.save_alt_outlined,
            color: AppColors.textOnDarkTertiary,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.event_saveDraft,
            style: const TextStyle(
              color: AppColors.textOnDarkTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSaveDraft(BuildContext context) async {
    final cubit = context.read<EventFormCubit>();
    final imageCubit = context.read<FormImageCubit>();
    final imageState = imageCubit.state;
    final imageData = imageState.whenOrNull(data: (data) => data);
    await cubit.saveDraft(
      localCoverImagePath: imageData?.hasLocalImage == true
          ? imageData?.localImagePath
          : null,
      remoteCoverImageUrl: imageData?.hasLocalImage != true
          ? imageData?.remoteImageUrl
          : null,
    );
  }
}
