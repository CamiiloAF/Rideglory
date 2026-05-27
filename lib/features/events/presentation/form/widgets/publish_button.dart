import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

class PublishButton extends StatelessWidget {
  const PublishButton({
    super.key,
    required this.isLoading,
    required this.isEditing,
  });

  final bool isLoading;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () => _onPublish(context),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isLoading
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(AppColors.darkBgPrimary),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEditing ? Icons.save_outlined : Icons.send_rounded,
                    color: AppColors.darkBgPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing
                        ? context.l10n.event_updateEvent
                        : context.l10n.event_publishEvent,
                    style: const TextStyle(
                      color: AppColors.darkBgPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _onPublish(BuildContext context) async {
    final cubit = context.read<EventFormCubit>();
    final imageCubit = context.read<FormImageCubit>();
    final event = await cubit.buildEventToSave();
    if (event != null) {
      final imageState = imageCubit.state;
      final imageData = imageState.whenOrNull(data: (data) => data);
      await cubit.saveEvent(
        event,
        localCoverImagePath: imageData?.hasLocalImage == true
            ? imageData?.localImagePath
            : null,
        remoteCoverImageUrl: imageData?.hasLocalImage != true
            ? imageData?.remoteImageUrl
            : null,
      );
    }
  }
}
