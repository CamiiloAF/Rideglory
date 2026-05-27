import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';

class InscriptionSecondaryActionButton extends StatelessWidget {
  const InscriptionSecondaryActionButton({
    super.key,
    required this.status,
    required this.onPressed,
  });

  final RegistrationStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    AppButtonVariant variant;
    AppButtonStyle style = AppButtonStyle.filled;

    switch (status) {
      case RegistrationStatus.approved:
        label = context.l10n.registration_myRegistration;
        icon = Icons.check_circle_outline;
        variant = AppButtonVariant.primary;
        break;
      case RegistrationStatus.pending:
        label = context.l10n.registration_viewDetail;
        icon = Icons.visibility_outlined;
        variant = AppButtonVariant.primary;
        style = AppButtonStyle.outlined;
        break;
      case RegistrationStatus.readyForEdit:
        label = context.l10n.event_edit;
        icon = Icons.edit_outlined;
        variant = AppButtonVariant.primary;
        style = AppButtonStyle.outlined;
        break;
      case RegistrationStatus.rejected:
        label = context.l10n.registration_reason;
        icon = Icons.info_outline;
        variant = AppButtonVariant.primary;
        style = AppButtonStyle.outlined;
        break;
      case RegistrationStatus.cancelled:
        label = context.l10n.registration_reRegister;
        icon = Icons.refresh;
        variant = AppButtonVariant.primary;
        style = AppButtonStyle.outlined;
        break;
    }

    return AppButton(
      label: label,
      icon: icon,
      variant: variant,
      style: style,
      onPressed: onPressed,
      isFullWidth: true,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
