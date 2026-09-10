import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../tokens/app_colors.dart';

/// Botón flotante circular de SOS sobre el mapa de la rodada en vivo
/// (LV1, LV1b, LV5a). Siempre `$c-error-solid` con texto/ícono
/// `$c-on-block` — nunca el acento de marca para una acción de
/// emergencia.
///
/// Pencil: yVKpQ
class SosButton extends StatelessWidget {
  const SosButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Material(
      color: colors.errorSolid,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 68,
          height: 68,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.siren, size: 22, color: colors.onBlock),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: colors.onBlock,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
