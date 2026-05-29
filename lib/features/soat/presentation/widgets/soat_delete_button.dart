import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';

/// Botón destructivo reutilizable para eliminar el SOAT de un vehículo.
///
/// Muestra el diálogo de confirmación, ejecuta [onDelete] (que debe devolver
/// `true` en éxito) y, al confirmar el éxito, invoca [onDeleted]. El manejo del
/// SnackBar de error vive aquí; el de éxito lo decide cada pantalla mediante
/// [onDeleted].
class SoatDeleteButton extends StatefulWidget {
  const SoatDeleteButton({
    super.key,
    required this.onDelete,
    required this.onDeleted,
  });

  /// Ejecuta el borrado real (cubit o usecase). Devuelve `true` en éxito.
  final Future<bool> Function() onDelete;

  /// Se llama tras un borrado exitoso (refrescar estado, navegar, etc.).
  final VoidCallback onDeleted;

  @override
  State<SoatDeleteButton> createState() => _SoatDeleteButtonState();
}

class _SoatDeleteButtonState extends State<SoatDeleteButton> {
  bool _deleting = false;

  Future<void> _confirmAndDelete() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: context.l10n.soat_delete_confirm_title,
      content: context.l10n.soat_delete_confirm_message,
      confirmLabel: context.l10n.soat_delete_button,
      confirmType: DialogActionType.danger,
      icon: Icons.delete_outline,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final success = await widget.onDelete();
    if (!mounted) return;

    if (success) {
      widget.onDeleted();
    } else {
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorOccurred)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: context.l10n.soat_delete_button,
      icon: Icons.delete_outline,
      onPressed: _deleting ? null : _confirmAndDelete,
      isLoading: _deleting,
      variant: AppButtonVariant.danger,
      style: AppButtonStyle.outlined,
    );
  }
}
