import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_next_date_pill.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_next_km_pill.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/next_service_row.dart';

class MaintenanceNextServiceCard extends StatefulWidget {
  final bool isCompleted;
  final int? currentMileage;
  final int? initialNextMileage;
  final DateTime? initialNextDate;
  final int? baseKm;

  const MaintenanceNextServiceCard({
    super.key,
    required this.isCompleted,
    this.currentMileage,
    this.initialNextMileage,
    this.initialNextDate,
    this.baseKm,
  });

  @override
  State<MaintenanceNextServiceCard> createState() =>
      _MaintenanceNextServiceCardState();
}

class _MaintenanceNextServiceCardState
    extends State<MaintenanceNextServiceCard> {
  DateTime? _nextDate;
  int? _relativeKm;

  @override
  void initState() {
    super.initState();
    _nextDate = widget.initialNextDate;
    _relativeKm = widget.initialNextMileage;
  }

  int? get _daysLeft {
    if (_nextDate == null) return null;
    final diff = _nextDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  int? get _estimatedKm {
    if (_relativeKm == null) return null;
    return (widget.baseKm ?? 0) + _relativeKm!;
  }

  @override
  Widget build(BuildContext context) {
    final estimated = _estimatedKm;
    final daysLeft = _daysLeft;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.flag_outlined,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NextServiceRow(
                  label: context.l10n.maintenance_prox_service_in,
                  pill: MaintenanceNextKmPill(
                    onChanged: (km) => setState(() => _relativeKm = km),
                  ),
                ),
                const SizedBox(height: 8),
                NextServiceRow(
                  label: context.l10n.maintenance_form_date_scheduled_label,
                  pill: MaintenanceNextDatePill(
                    onChanged: (date) => setState(() => _nextDate = date),
                  ),
                ),
                if (estimated != null || daysLeft != null) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.darkBorderPrimary),
                  const SizedBox(height: 10),
                  if (estimated != null)
                    Text(
                      'El próximo servicio será a los $estimated km',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textOnDarkTertiary,
                      ),
                    ),
                  if (daysLeft != null) ...[
                    if (estimated != null) const SizedBox(height: 4),
                    Text(
                      'Faltan $daysLeft días para el servicio',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textOnDarkTertiary,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
