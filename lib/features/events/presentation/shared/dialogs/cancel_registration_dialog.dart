import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class CancelRegistrationDialog {
  /// Muestra el diálogo de confirmación para cancelar una inscripción
  ///
  /// Retorna `true` si el usuario confirmó y la cancelación fue exitosa,
  /// `false` si el usuario canceló o la operación falló
  static Future<bool> show({
    required BuildContext context,
    required Future<bool> Function() onCancel,
    bool showSuccessMessage = true,
  }) async {
    var confirmed = false;

    await ConfirmationDialog.show(
      context: context,
      title: context.l10n.event_cancelRegistrationTitle,
      content: context.l10n.event_cancelRegistrationMessage,
      dialogType: DialogType.warning,
      confirmLabel: context.l10n.accept,
      confirmType: DialogActionType.danger,
      onConfirm: () {
        confirmed = true;
      },
    );

    if (!confirmed || !context.mounted) return false;

    final success = await onCancel();

    if (success && showSuccessMessage && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.event_cancelRegistrationSuccess),
          backgroundColor: Colors.green,
        ),
      );
    }

    return success;
  }

  /// Versión simplificada que ejecuta el callback directamente sin esperar resultado
  ///
  /// Útil cuando la cancelación se maneja a través de un cubit/bloc
  static Future<void> showAndExecute({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) async {
    await ConfirmationDialog.show(
      context: context,
      title: context.l10n.event_cancelRegistrationTitle,
      content: context.l10n.event_cancelRegistrationMessage,
      dialogType: DialogType.warning,
      confirmLabel: context.l10n.accept,
      confirmType: DialogActionType.danger,
      onConfirm: onConfirm,
    );
  }
}
