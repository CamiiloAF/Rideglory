import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

/// "Atrás" + "Continuar" (create) / "Listo" (edit) row for steps 0–2.
///
/// Design spec (Pencil EzQtb):
/// - "Atrás": fill #242429, text "Atrás" white, cornerRadius 26, h=52
/// - "Continuar": fill #F98C1F, dark text + chevron-right, cornerRadius 26, h=52
/// - Gap: 12px
class NavigationRow extends StatelessWidget {
  const NavigationRow({
    super.key,
    required this.currentStep,
    required this.isSaving,
    required this.cubit,
  });

  final int currentStep;
  final bool isSaving;
  final EventFormCubit cubit;

  Future<void> _onSaveStep(BuildContext context) async {
    if (!cubit.validateStep(currentStep)) return;
    final imageCubit = context.read<FormImageCubit>();
    final event = await cubit.buildEventToSave();
    if (!context.mounted || event == null) return;
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

  @override
  Widget build(BuildContext context) {
    final isEditing = cubit.isEditing;
    // En modo edición, el botón Atrás siempre vuelve al overview (step 3).
    // En creación, solo se muestra en steps > 0.
    final showBack = isEditing || currentStep > 0;

    return Row(
      children: [
        if (showBack) ...[
          Expanded(
            child: AppButton(
              label: context.l10n.event_step_back,
              onPressed: isSaving
                  ? null
                  : () {
                      if (isEditing) {
                        cubit.goToStep(3);
                      } else {
                        cubit.prevStep();
                      }
                    },
              variant: AppButtonVariant.ghost,
              shape: AppButtonShape.pill,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: isEditing
              ? AppButton(
                  label: context.l10n.event_step_done,
                  isLoading: isSaving,
                  onPressed: isSaving ? null : () => _onSaveStep(context),
                  shape: AppButtonShape.pill,
                )
              : AppButton(
                  label: context.l10n.event_step_continue,
                  onPressed: isSaving
                      ? null
                      : () {
                          bool imageValid = true;
                          if (currentStep == 0) {
                            final imageData = context
                                .read<FormImageCubit>()
                                .state
                                .whenOrNull(data: (d) => d);
                            final hasImage =
                                imageData?.hasLocalImage == true ||
                                imageData?.remoteImageUrl?.isNotEmpty == true;
                            imageValid =
                                cubit.validateImageRequired(hasImage);
                          }
                          final stepValid = cubit.validateStep(currentStep);
                          if (imageValid && stepValid) cubit.nextStep();
                        },
                  shape: AppButtonShape.pill,
                ),
        ),
      ],
    );
  }
}
