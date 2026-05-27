import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Tarjeta que muestra el estado de vigencia del SOAT calculado a partir de
/// las fechas ingresadas en el formulario, sin depender de ningún BLoC.
///
/// Refleja los mismos estados que [SoatValidAlert] pero recibe las fechas
/// directamente como parámetros para que funcione con estado local.
class SoatValidityCard extends StatelessWidget {
  const SoatValidityCard({
    super.key,
    required this.startDate,
    required this.expiryDate,
  });

  final DateTime? startDate;
  final DateTime? expiryDate;

  @override
  Widget build(BuildContext context) {
    // Sin fechas → estado pendiente
    if (startDate == null || expiryDate == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkTertiary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 20,
              color: AppColors.textOnDarkTertiary,
            ),
            const SizedBox(width: 10),
            Text(
              context.l10n.vehicle_soat_status_pending,
              style: const TextStyle(
                color: AppColors.textOnDarkTertiary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Fechas inválidas: inicio >= vencimiento
    if (!startDate!.isBefore(expiryDate!)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 20, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.vehicle_soat_status_invalid_dates_title,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.vehicle_soat_status_invalid_dates_desc,
                    style: const TextStyle(
                      color: AppColors.textOnDarkSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final daysRemaining = expiryDate!
        .difference(DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ))
        .inDays;

    // SOAT vencido
    if (daysRemaining < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 20,
              color: AppColors.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.vehicle_soat_status_expired_title,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n
                        .vehicle_soat_status_expired_desc(daysRemaining.abs()),
                    style: const TextStyle(
                      color: AppColors.textOnDarkSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // SOAT vigente
    const validColor = Color(0xFF22C55E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: validColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 20,
            color: validColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.vehicle_soat_status_valid,
                  style: const TextStyle(
                    color: validColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  daysRemaining == 0
                      ? context.l10n.vehicle_soat_status_expires_today
                      : context.l10n
                          .vehicle_soat_status_valid_desc(daysRemaining),
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
