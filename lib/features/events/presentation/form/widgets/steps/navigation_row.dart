import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';

/// "Atrás" + "Continuar" row for steps 1–3 of the event creation wizard.
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (currentStep > 0) ...[
          Expanded(
            child: AppButton(
              label: context.l10n.event_step_back,
              onPressed: isSaving ? null : cubit.prevStep,
              variant: AppButtonVariant.ghost,
              shape: AppButtonShape.pill,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: AppButton(
            label: context.l10n.event_step_continue,
            onPressed: isSaving
                ? null
                : () {
                    if (cubit.validateStep(currentStep)) {
                      cubit.nextStep();
                    }
                  },
            shape: AppButtonShape.pill,
          ),
        ),
      ],
    );
  }
}
