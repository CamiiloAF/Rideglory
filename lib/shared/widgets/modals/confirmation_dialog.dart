import 'package:flutter/material.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

class ConfirmationDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    VoidCallback? onConfirm,
    void Function(BuildContext dialogContext)? onCancel,
    String cancelLabel = AppStrings.cancel,
    String confirmLabel = AppStrings.confirm,
    DialogActionType confirmType = DialogActionType.primary,
    DialogType dialogType = DialogType.confirmation,
    bool isDismissible = false,
  }) {
    return showDialog(
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
                        const SizedBox(width: 12),
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
                    const SizedBox(height: 16),
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
                        label: cancelLabel,
                        onPressed: onCancel != null
                            ? () => onCancel(dialogContext)
                            : () => Navigator.of(dialogContext).pop(false),
                        variant: AppButtonVariant.outline,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: confirmLabel,
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
