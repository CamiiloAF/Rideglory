import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

/// Bottom bar for the event form containing the primary "Publicar evento" CTA
/// and the "Guardar como borrador" secondary link.
///
/// Matches Pencil frame zbCa0 — "CTA" section:
/// - Pill button h=56, radius=28, accent fill, send icon
/// - Draft text link below (only in create mode)
class EventFormBottomBar extends StatelessWidget {
  const EventFormBottomBar({
    super.key,
    required this.isLoading,
    required this.isEditing,
  });

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
          _PublishButton(isLoading: isLoading, isEditing: isEditing),
          if (!isEditing) ...[
            const SizedBox(height: 8),
            _DraftLink(),
          ],
        ],
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  const _PublishButton({required this.isLoading, required this.isEditing});

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

class _DraftLink extends StatelessWidget {
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
