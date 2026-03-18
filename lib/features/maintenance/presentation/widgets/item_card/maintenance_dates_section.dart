import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

/// Widget para la sección de fechas del mantenimiento
class MaintenanceDatesSection extends StatelessWidget {
  final MaintenanceModel maintenance;
  final int? daysUntilNext;

  const MaintenanceDatesSection({
    super.key,
    required this.maintenance,
    required this.daysUntilNext,
  });

  String _formatDate(BuildContext context, DateTime date) {
    final months = [
      context.l10n.maintenance_monthJan,
      context.l10n.maintenance_monthFeb,
      context.l10n.maintenance_monthMar,
      context.l10n.maintenance_monthApr,
      context.l10n.maintenance_monthMay,
      context.l10n.maintenance_monthJun,
      context.l10n.maintenance_monthJul,
      context.l10n.maintenance_monthAug,
      context.l10n.maintenance_monthSep,
      context.l10n.maintenance_monthOct,
      context.l10n.maintenance_monthNov,
      context.l10n.maintenance_monthDec,
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
            SizedBox(width: 8),
            Text(
              'Realizado: ${_formatDate(context, maintenance.date)}',
              style: context.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        if (maintenance.nextMaintenanceDate != null) ...[
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 16,
                color: daysUntilNext != null && daysUntilNext! <= 0
                    ? const Color(0xFFEF4444)
                    : Colors.grey[600],
              ),
              SizedBox(width: 8),
              Text(
                'Próximo: ${_formatDate(context, maintenance.nextMaintenanceDate!)}',
                style: context.bodySmall?.copyWith(
                  color: daysUntilNext != null && daysUntilNext! <= 0
                      ? const Color(0xFFEF4444)
                      : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (daysUntilNext != null) ...[
                SizedBox(width: 8),
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
