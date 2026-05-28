import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Confirmation modal (affirmative + cancel) built on the unified [AppModal]
/// design. Returns `true` when confirmed, `false`/`null` when cancelled.
class ConfirmationDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    VoidCallback? onConfirm,
    void Function(BuildContext dialogContext)? onCancel,
    String? cancelLabel,
    String? confirmLabel,
    IconData? icon,
    DialogActionType confirmType = DialogActionType.primary,
    DialogType dialogType = DialogType.confirmation,
    bool isDismissible = false,
  }) {
    final resolvedCancelLabel = cancelLabel ?? context.l10n.cancel;
    final resolvedConfirmLabel = confirmLabel ?? context.l10n.confirm;

    // A destructive confirm drives the whole modal into the `destructive`
    // variant (red icon + red button) so the icon and button stay consistent;
    // otherwise the modal follows the requested [dialogType].
    final variant = confirmType == DialogActionType.danger
        ? AppModalVariant.destructive
        : dialogType.variant;

    return AppModal.show<bool>(
      context: context,
      title: title,
      description: content,
      variant: variant,
      icon: icon,
      barrierDismissible: isDismissible,
      actions: [
        AppModalAction(
          label: resolvedConfirmLabel,
          emphasis: confirmType == DialogActionType.danger
              ? AppModalActionEmphasis.danger
              : AppModalActionEmphasis.primary,
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
        ),
        AppModalAction.neutral(
          label: resolvedCancelLabel,
          onPressed: onCancel != null
              ? () => onCancel(context)
              : () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
