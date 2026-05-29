import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// End-ride confirmation modal (Pencil page 21), unified with [AppModal].
class EndRideConfirmDialog {
  static Future<bool?> show({required BuildContext context}) {
    return AppModal.show<bool>(
      context: context,
      title: context.l10n.map_endRideConfirmTitle,
      description: context.l10n.map_endRideConfirmMessage,
      icon: Icons.flag_rounded,
      variant: AppModalVariant.warning,
      barrierDismissible: true,
      actions: [
        AppModalAction(
          label: context.l10n.map_endRideConfirmButton,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
        AppModalAction.neutral(
          label: context.l10n.cancel,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
      ],
    );
  }
}
