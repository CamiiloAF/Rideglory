import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class ConfirmationDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    VoidCallback? onConfirm,
    void Function(BuildContext dialogContext)? onCancel,
    String? cancelLabel,
    String? confirmLabel,
    DialogActionType confirmType = DialogActionType.primary,
    DialogType dialogType = DialogType.confirmation,
    bool isDismissible = false,
  }) {
    final resolvedCancelLabel = cancelLabel ?? context.l10n.cancel;
    final resolvedConfirmLabel = confirmLabel ?? context.l10n.confirm;

    return showDialog<bool>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          dialogType.icon,
                          color: dialogType.color,
                          size: 28,
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Text(
                            title,
                            style: dialogContext.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapLg,
                    // Content
                    Text(
                      content,
                      style: dialogContext.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: resolvedCancelLabel,
                        onPressed: onCancel != null
                            ? () => onCancel(dialogContext)
                            : () => Navigator.of(dialogContext).pop(false),
                        variant: AppButtonVariant.primary,
                        style: AppButtonStyle.outlined,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: AppButton(
                        label: resolvedConfirmLabel,
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                          if (onConfirm != null) {
                            onConfirm();
                          }
                        },
                        variant: confirmType == DialogActionType.danger
                            ? AppButtonVariant.danger
                            : AppButtonVariant.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
