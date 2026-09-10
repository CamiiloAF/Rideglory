import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radii.dart';

/// Botón principal: fondo `$c-accent`, texto/ícono `$c-on-accent` (oscuro).
///
/// [destructive] cambia el fondo a `$c-error-solid` con texto claro, para
/// confirmaciones de borrado — nunca el acento de marca para una acción
/// destructiva.
///
/// Pencil: HYvT4
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.compact = false,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool destructive;

  /// `true` para un botón de 48 de alto, ancho ajustado al contenido
  /// (nunca `double.infinity`) y padding horizontal 18 — para cuando el
  /// botón comparte una fila con otro elemento (header de rodada en
  /// vivo, banner de SOS ajeno) en vez de ocupar la pantalla completa.
  final bool compact;

  /// Overrides puntuales para paletas que no son ni el acento por
  /// defecto ni [destructive] (ej. el botón blanco-sobre-rojo del banner
  /// de SOS ajeno) — para no inventar un `ElevatedButton` ad hoc ni un
  /// hex nuevo en el sitio de uso.
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final background =
        backgroundColor ?? (destructive ? colors.errorSolid : colors.accent);
    final foreground =
        foregroundColor ?? (destructive ? colors.plateText : colors.onAccent);
    return SizedBox(
      width: compact ? null : double.infinity,
      height: compact ? 48 : 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          disabledBackgroundColor: background.withValues(alpha: 0.4),
          foregroundColor: foreground,
          padding: compact ? const EdgeInsets.symmetric(horizontal: 18) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              compact ? AppRadii.sm : AppRadii.md,
            ),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: compact ? 16 : 21, color: foreground),
              SizedBox(width: compact ? 8 : 9),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 14 : 16.5,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
