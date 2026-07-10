import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class DeleteAccountConfirmButton extends StatelessWidget {
  const DeleteAccountConfirmButton({
    super.key,
    required this.isEnabled,
    required this.isLoading,
    required this.isRetry,
    required this.onPressed,
  });

  final bool isEnabled;
  final bool isLoading;
  final bool isRetry;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppButton(
      label: isLoading
          ? l10n.profile_deleteAccount_confirmButtonLoading
          : isRetry
          ? l10n.profile_deleteAccount_retryButton
          : l10n.profile_deleteAccount_confirmButton,
      onPressed: isEnabled && !isLoading ? onPressed : null,
      isLoading: isLoading,
      icon: Icons.delete_outline,
      variant: AppButtonVariant.danger,
      height: 52,
      shape: AppButtonShape.pill,
    );
  }
}
