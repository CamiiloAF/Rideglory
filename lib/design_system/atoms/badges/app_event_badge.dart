import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

/// Variants for the [AppEventBadge] atom.
enum EventBadgeVariant {
  /// Evento disponible / programado (upcoming).
  available,

  /// Alias for available — kept for backwards compatibility.
  scheduled,

  /// Evento en curso.
  inProgress,

  /// Evento finalizado / completado.
  finished,

  /// Evento cancelado.
  cancelled,

  /// Evento lleno / sold out.
  full,

  /// Próximamente.
  comingSoon,

  /// Evento gratuito.
  free,

  /// Evento de pago.
  paid,
}

/// A small status badge used on event cards and event detail screens.
///
/// Spec (zKkmE): pill, cornerRadius 20, padding [5, 12], text 11px/700/white,
/// solid fill background.
class AppEventBadge extends StatelessWidget {
  const AppEventBadge({
    required this.label,
    this.variant,
    this.color,
    super.key,
  });

  final String label;
  final EventBadgeVariant? variant;

  /// Override fill color. Takes precedence over [variant].
  final Color? color;

  Color _backgroundColor() {
    if (color != null) return color!;
    return switch (variant ?? EventBadgeVariant.available) {
      EventBadgeVariant.available ||
      EventBadgeVariant.scheduled => AppColors.info,
      EventBadgeVariant.inProgress => AppColors.success,
      EventBadgeVariant.full => AppColors.error,
      EventBadgeVariant.comingSoon => AppColors.warning,
      EventBadgeVariant.cancelled => AppColors.tabInactive,
      EventBadgeVariant.finished => AppColors.tabInactive,
      EventBadgeVariant.free => AppColors.success,
      EventBadgeVariant.paid => AppColors.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}
