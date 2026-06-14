import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

/// Fila de acciones del step 4.
///
/// - Modo creación: "Publicar evento" (guarda y cierra).
/// - Modo edición: "Cerrar" (los cambios ya se guardaron por sección).
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
    if (cubit.isEditing) {
      return AppButton(
        label: context.l10n.event_step_close,
        onPressed: () {
          final savedEvent =
              cubit.state.saveResult.whenOrNull(data: (event) => event);
          Navigator.of(context).pop(savedEvent);
        },
        variant: AppButtonVariant.ghost,
        shape: AppButtonShape.pill,
        height: 52,
      );
    }

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
}
