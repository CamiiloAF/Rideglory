import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class GarageMaintenanceCard extends StatelessWidget {
  const GarageMaintenanceCard({
    super.key,
    required this.isNext,
    required this.maintenance,
    required this.vehicle,
    this.isOverdue = false,
  });

  final bool isNext;
  final MaintenanceModel? maintenance;
  final VehicleModel vehicle;
  final bool isOverdue;

  String _formatKm(int km) => km.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  String _formatDate(DateTime date) =>
      DateFormat('MMM yyyy', 'es').format(date);

  String get _dateText {
    if (maintenance == null) return '—';
    if (isNext) {
      final date = maintenance!.nextDate;
      return date != null ? _formatDate(date) : '—';
    }
    final date = maintenance!.serviceDate;
    return date != null ? _formatDate(date) : '—';
  }

  String get _valueText {
    if (maintenance == null) return '—';
    if (isNext) {
      final km = maintenance!.nextOdometer;
      if (km != null) return '${_formatKm(km)} km';
      final date = maintenance!.nextDate;
      return date != null ? DateFormat('d MMM. yyyy', 'es').format(date) : '—';
    }
    final km = maintenance!.odometerAtService;
    if (km != null) return '${_formatKm(km)} km';
    final date = maintenance!.serviceDate;
    return date != null ? DateFormat('d MMM. yyyy', 'es').format(date) : '—';
  }

  Color get _cardBg {
    if (!isNext) return AppColors.darkCard;
    return isOverdue
        ? AppColors.statusError.withValues(alpha: 0.1)
        : AppColors.statusWarning.withValues(alpha: 0.06);
  }

  Color get _cardBorder {
    if (!isNext) return AppColors.darkBorderPrimary;
    return isOverdue
        ? AppColors.statusError.withValues(alpha: 0.25)
        : AppColors.statusWarning.withValues(alpha: 0.19);
  }

  Color get _iconColor {
    if (!isNext) return AppColors.primary;
    return isOverdue ? AppColors.statusError : AppColors.statusWarning;
  }

  Color get _iconBg {
    if (!isNext) return AppColors.primarySubtle;
    return isOverdue
        ? AppColors.statusError.withValues(alpha: 0.13)
        : AppColors.statusWarning.withValues(alpha: 0.13);
  }

  Color get _badgeColor {
    if (!isNext) return AppColors.statusGreen;
    return isOverdue ? AppColors.statusError : AppColors.statusWarning;
  }

  Color get _valueColor {
    if (!isNext) return AppColors.textOnDarkSecondary;
    return isOverdue ? AppColors.statusError : AppColors.statusWarning;
  }

  @override
  Widget build(BuildContext context) {
    final badgeLabel = isNext
        ? context.l10n.garage_healthUpcoming.toUpperCase()
        : context.l10n.garage_completedServiceBadge;

    final badgeIcon = isNext ? Icons.schedule : Icons.task_alt;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(badgeIcon, size: 12, color: _badgeColor),
                  const SizedBox(width: 4),
                  Text(
                    badgeLabel,
                    style: TextStyle(
                      color: _badgeColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Text(
                _dateText,
                style: const TextStyle(
                  color: AppColors.textOnDarkTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isNext ? Icons.build : Icons.water_drop,
                  size: 14,
                  color: _iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  maintenance?.name ?? '—',
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _valueText,
            style: TextStyle(
              color: _valueColor,
              fontSize: 11,
              fontWeight: isNext ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
