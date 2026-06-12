import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

/// "Publicar evento" + "Guardar borrador" column for step 4 of the event wizard.
///
/// Design spec (Pencil FW3Hd):
/// - "Publicar Evento": #F98C1F pill h=52, icon send (dark), text dark, gap 8
/// - "Guardar como borrador": #242429 pill h=44, cornerRadius 22, text gray #9CA3AF
/// - Gap between buttons: 10px
class PublishRow extends StatelessWidget {
  const PublishRow({
    super.key,
    required this.isSaving,
    required this.cubit,
  });

  final bool isSaving;
  final EventFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: context.l10n.event_step_review_publishButton,
          isLoading: isSaving,
          onPressed: isSaving ? null : () => _onPublish(context),
          icon: Icons.send_rounded,
          shape: AppButtonShape.pill,
          height: 52,
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: isSaving ? null : () => _onSaveDraft(context),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.darkTertiary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                context.l10n.event_step_saveDraft,
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onPublish(BuildContext context) async {
    final imageCubit = context.read<FormImageCubit>();
    final event = await cubit.buildEventToSave();
    if (!context.mounted) return;
    if (event != null) {
      final imageState = imageCubit.state;
      final imageData = imageState.whenOrNull(data: (data) => data);
      await cubit.saveEvent(
        event,
        localCoverImagePath:
            imageData?.hasLocalImage == true ? imageData?.localImagePath : null,
        remoteCoverImageUrl: imageData?.hasLocalImage != true
            ? imageData?.remoteImageUrl
            : null,
      );
    }
  }

  Future<void> _onSaveDraft(BuildContext context) async {
    final imageCubit = context.read<FormImageCubit>();
    final imageState = imageCubit.state;
    final imageData = imageState.whenOrNull(data: (data) => data);
    await cubit.saveDraft(
      localCoverImagePath:
          imageData?.hasLocalImage == true ? imageData?.localImagePath : null,
      remoteCoverImageUrl: imageData?.hasLocalImage != true
          ? imageData?.remoteImageUrl
          : null,
    );
  }
}
