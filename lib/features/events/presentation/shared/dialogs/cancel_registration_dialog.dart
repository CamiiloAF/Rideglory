import 'package:flutter/material.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

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
      title: EventStrings.cancelRegistrationTitle,
      content: EventStrings.cancelRegistrationMessage,
      dialogType: DialogType.warning,
      confirmLabel: AppStrings.accept,
      confirmType: DialogActionType.danger,
      onConfirm: () {
        confirmed = true;
      },
    );

    if (!confirmed || !context.mounted) return false;

    final success = await onCancel();

    if (success && showSuccessMessage && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(EventStrings.cancelRegistrationSuccess),
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
      title: EventStrings.cancelRegistrationTitle,
      content: EventStrings.cancelRegistrationMessage,
      dialogType: DialogType.warning,
      confirmLabel: AppStrings.accept,
      confirmType: DialogActionType.danger,
      onConfirm: onConfirm,
    );
  }
}
