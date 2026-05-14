import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_content.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

/// Event creation / edit form screen.
///
/// Header matches Pencil page 11:
///   - Back arrow (left) + "Crear Evento" title (center) + "Cancelar" link (right)
///
/// Bottom bar: large orange "Publicar evento" pill button.
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
          // ── Custom header matching Pencil design ─────────────────────
          appBar: AppBar(
            backgroundColor: AppColors.darkBgPrimary,
            foregroundColor: AppColors.textOnDarkPrimary,
            elevation: 0,
            // Back arrow — left
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textOnDarkPrimary,
              ),
              onPressed: () => context.pop(),
            ),
            // Title — center
            centerTitle: true,
            title: Text(
              isEditing
                  ? context.l10n.event_editEvent
                  : context.l10n.event_newEvent,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            // "Cancelar" — right
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  context.l10n.cancel,
                  style: const TextStyle(
                    color: AppColors.textOnDarkTertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          body: const EventFormContent(),
          bottomNavigationBar: _FormBottomBar(
            isLoading: isSaving,
            isEditing: isEditing,
          ),
        );
      },
    );
  }
}

/// Bottom bar with the publish / update CTA.
/// Matches Pencil "CTA" section: large pill button h=56, radius=28.
class _FormBottomBar extends StatelessWidget {
  const _FormBottomBar({required this.isLoading, required this.isEditing});

  final bool isLoading;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBgPrimary,
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, max(16.0, bottomPadding)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Publish button
          GestureDetector(
            onTap: isLoading ? null : () => _onPublish(context),
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isLoading ? AppColors.primary.withValues(alpha: 0.6) : AppColors.primary,
                borderRadius: BorderRadius.circular(28),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.darkBgPrimary),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEditing
                              ? Icons.save_outlined
                              : Icons.send_rounded,
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
          ),
          const SizedBox(height: 8),
          // Draft link — only for new events
          if (!isEditing)
            GestureDetector(
              onTap: () => context.pop(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_alt_outlined,
                      color: AppColors.textOnDarkTertiary, size: 14),
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
            ),
        ],
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
