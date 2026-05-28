import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Bottom navigation bar for the registration wizard. Shows a back button on
/// every step but the first, and a primary action that reads "Siguiente" until
/// the last step, where it becomes the submit/finish action.
class RegistrationWizardNavigationBar extends StatelessWidget {
  const RegistrationWizardNavigationBar({
    super.key,
    required this.isFirstStep,
    required this.isLastStep,
    required this.isEditing,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  final bool isFirstStep;
  final bool isLastStep;
  final bool isEditing;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final String primaryLabel;
    if (isLastStep) {
      primaryLabel = isEditing
          ? context.l10n.registration_updateRegistration
          : context.l10n.registration_finishRegistration;
    } else {
      primaryLabel = context.l10n.registration_nextStep;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBgPrimary,
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!isFirstStep) ...[
              Expanded(
                child: AppButton(
                  label: context.l10n.registration_previousStep,
                  onPressed: isLoading ? null : onBack,
                  style: AppButtonStyle.outlined,
                  shape: AppButtonShape.pill,
                  height: 52,
                ),
              ),
              AppSpacing.hGapMd,
            ],
            Expanded(
              flex: isFirstStep ? 1 : 2,
              child: AppButton(
                label: primaryLabel,
                onPressed: isLastStep ? onSubmit : onNext,
                isLoading: isLoading,
                shape: AppButtonShape.pill,
                height: 52,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
