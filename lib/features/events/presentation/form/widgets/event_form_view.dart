import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_bottom_bar.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_content.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

/// Event creation / edit form screen.
///
/// Header matches Pencil frame zbCa0:
///   - "Cancelar" text button (left, text-secondary) — pops the form
///   - "Nuevo Evento" / "Editar Evento" title (center, w600)
///   - "Publicar" accent text button (right)
///
/// Bottom bar: large orange "Publicar evento" pill button via [EventFormBottomBar].
class EventFormView extends StatelessWidget {
  const EventFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventFormCubit, EventFormState>(
      listenWhen: (previous, current) =>
          previous.saveResult != current.saveResult ||
          previous.coverGenerationResult != current.coverGenerationResult,
      listener: (context, state) {
        state.saveResult.whenOrNull(
          data: (event) {
            final isEditing = context.read<EventFormCubit>().isEditing;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditing
                      ? context.l10n.event_eventUpdatedSuccess
                      : context.l10n.event_eventCreatedSuccess,
                ),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop(event);
          },
          error: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.errorMessage(error.message)),
                backgroundColor: AppColors.error,
              ),
            );
          },
        );

        state.coverGenerationResult.whenOrNull(
          data: (imageUrl) {
            context.read<FormImageCubit>().setRemoteImageUrl(imageUrl);
          },
          error: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.event_coverGenerateError),
                backgroundColor: AppColors.error,
              ),
            );
            context.read<EventFormCubit>().resetCoverGeneration();
          },
        );
      },
      builder: (context, state) {
        final cubit = context.read<EventFormCubit>();
        final isEditing = cubit.isEditing;
        final isSaving = state.saveResult is Loading;

        return Scaffold(
          backgroundColor: AppColors.darkBgPrimary,
          appBar: AppBar(
            backgroundColor: AppColors.darkBgPrimary,
            foregroundColor: AppColors.textOnDarkPrimary,
            elevation: 0,
            automaticallyImplyLeading: false,
            // "Cancelar" — left
            leading: TextButton(
              onPressed: () => context.pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textOnDarkSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                context.l10n.event_form_cancel_action,
                style: const TextStyle(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            // Title — center
            centerTitle: true,
            title: Text(
              isEditing
                  ? context.l10n.event_editEvent
                  : context.l10n.event_newEvent,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            // "Publicar" — right
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => _onPublish(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(
                  context.l10n.event_form_publish_action,
                  style: TextStyle(
                    color: isSaving
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          body: const EventFormContent(),
          bottomNavigationBar: EventFormBottomBar(
            isLoading: isSaving,
            isEditing: isEditing,
          ),
        );
      },
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
        localCoverImagePath:
            imageData?.hasLocalImage == true ? imageData?.localImagePath : null,
        remoteCoverImageUrl: imageData?.hasLocalImage != true
            ? imageData?.remoteImageUrl
            : null,
      );
    }
  }
}
