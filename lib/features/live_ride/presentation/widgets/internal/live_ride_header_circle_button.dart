import 'package:flutter/material.dart';

/// Botón circular translúcido 48x48 sobre el header flotante oscuro de
/// LV1/LV5a (volver, ver riders). Interno del feature: el header de otras
/// pantallas usa `HeaderIconButton`, que asume texto/fondo claros, no el
/// scrim oscuro de la rodada en vivo.
class LiveRideHeaderCircleButton extends StatelessWidget {
  const LiveRideHeaderCircleButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: foreground),
        ),
      ),
    );
  }
}
