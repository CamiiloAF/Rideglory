import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Informational modal with a single dismiss button, built on the unified
/// [AppModal] design.
class InfoDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    String? buttonLabel,
    DialogType type = DialogType.information,
  }) {
    final resolvedButtonLabel = buttonLabel ?? context.l10n.accept;
    return AppModal.show<void>(
      context: context,
      title: title,
      description: content,
      variant: type.variant,
      barrierDismissible: true,
      actions: [AppModalAction(label: resolvedButtonLabel, onPressed: () {})],
    );
  }
}
