import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radii.dart';

/// Botón destructivo en `$c-error-solid`, nunca en el naranja de marca.
/// Reservado para "Continuar con el borrado" / "Sí, borrar mi cuenta".
///
/// Pencil: MCSBy, H69H3
class DeleteAccountDestructiveButton extends StatelessWidget {
  const DeleteAccountDestructiveButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.errorSolid,
          foregroundColor: colors.onBlock,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.onBlock,
          ),
        ),
      ),
    );
  }
}
