import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/theme/app_colors.dart';

/// Variants for the [AppEventBadge] atom.
enum EventBadgeVariant {
  /// Evento programado (upcoming).
  scheduled,

  /// Evento en curso.
  inProgress,

  /// Evento finalizado.
  finished,

  /// Evento cancelado.
  cancelled,

  /// Evento gratuito.
  free,

  /// Evento de pago.
  paid,
}

/// A small status badge used on event cards and event detail screens.
///
/// Height is 24 px, border radius 6 px, font 11 px / weight 700.
/// Caller is responsible for providing the localised [label] string via
/// `context.l10n.event_badge_<variant>`.
class AppEventBadge extends StatelessWidget {
  const AppEventBadge({
    required this.variant,
    required this.label,
    super.key,
  });

  final EventBadgeVariant variant;
  final String label;

  Color _backgroundColor() {
    return switch (variant) {
      EventBadgeVariant.scheduled => AppColors.primary.withValues(alpha: 0.15),
      EventBadgeVariant.inProgress =>
        AppColors.warning.withValues(alpha: 0.15),
      EventBadgeVariant.finished => AppColors.darkSurfaceHighest,
      EventBadgeVariant.cancelled => AppColors.error.withValues(alpha: 0.15),
      EventBadgeVariant.free => AppColors.eventFree.withValues(alpha: 0.15),
      EventBadgeVariant.paid => AppColors.eventPaid.withValues(alpha: 0.15),
    };
  }

  Color _foregroundColor() {
    return switch (variant) {
      EventBadgeVariant.scheduled => AppColors.primary,
      EventBadgeVariant.inProgress => AppColors.warning,
      EventBadgeVariant.finished => AppColors.darkTextSecondary,
      EventBadgeVariant.cancelled => AppColors.error,
      EventBadgeVariant.free => AppColors.eventFree,
      EventBadgeVariant.paid => AppColors.eventPaid,
    };
  }

  @override
  Widget build(BuildContext context) {
    final fg = _foregroundColor();
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          height: 1.0,
        ),
      ),
    );
  }
}
