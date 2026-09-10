import 'package:flutter/material.dart';

import '../../../../../design_system/tokens/app_colors.dart';
import '../../../../../l10n/l10n_extensions.dart';

/// Botón terciario "Ya estoy bien — cerrar SOS" de LV4a/LV4b. Interno del
/// feature: variante puntual de outline rojo que no repite en otra
/// pantalla como para justificar un componente compartido.
class SosCloseButton extends StatelessWidget {
  const SosCloseButton({
    required this.isBusy,
    required this.onPressed,
    super.key,
  });

  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isBusy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.errorText,
          side: BorderSide(color: colors.errorText, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          context.l10n.sos_close_cta,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
