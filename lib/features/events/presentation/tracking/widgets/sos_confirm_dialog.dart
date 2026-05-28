import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// SOS confirmation modal (Pencil page 20), unified with [AppModal].
class SosConfirmDialog {
  static Future<bool?> show({required BuildContext context}) {
    return AppModal.show<bool>(
      context: context,
      title: context.l10n.map_sosConfirmTitle,
      description: context.l10n.map_sosConfirmMessage,
      icon: Icons.sos_rounded,
      variant: AppModalVariant.destructive,
      barrierDismissible: true,
      actions: [
        AppModalAction(
          label: context.l10n.map_sosSend,
          emphasis: AppModalActionEmphasis.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        AppModalAction.neutral(
          label: context.l10n.cancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
