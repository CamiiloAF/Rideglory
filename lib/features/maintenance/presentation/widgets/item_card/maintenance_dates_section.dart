import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';

/// Widget para la sección de fechas del mantenimiento
class MaintenanceDatesSection extends StatelessWidget {
  final MaintenanceModel maintenance;
  final int? daysUntilNext;

  const MaintenanceDatesSection({
    super.key,
    required this.maintenance,
    required this.daysUntilNext,
  });

  String _formatDate(DateTime date) {
    final months = [
      MaintenanceStrings.monthJan,
      MaintenanceStrings.monthFeb,
      MaintenanceStrings.monthMar,
      MaintenanceStrings.monthApr,
      MaintenanceStrings.monthMay,
      MaintenanceStrings.monthJun,
      MaintenanceStrings.monthJul,
      MaintenanceStrings.monthAug,
      MaintenanceStrings.monthSep,
      MaintenanceStrings.monthOct,
      MaintenanceStrings.monthNov,
      MaintenanceStrings.monthDec,
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'Realizado: ${_formatDate(maintenance.date)}',
              style: context.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        if (maintenance.nextMaintenanceDate != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 16,
                color: daysUntilNext != null && daysUntilNext! <= 0
                    ? const Color(0xFFEF4444)
                    : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Próximo: ${_formatDate(maintenance.nextMaintenanceDate!)}',
                style: context.bodySmall?.copyWith(
                  color: daysUntilNext != null && daysUntilNext! <= 0
                      ? const Color(0xFFEF4444)
                      : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (daysUntilNext != null) ...[
                const SizedBox(width: 8),
                Text(
                  '($daysUntilNext días)',
                  style: context.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
