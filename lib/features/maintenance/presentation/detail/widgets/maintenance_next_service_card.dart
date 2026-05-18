import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

class MaintenanceNextServiceCard extends StatelessWidget {
  final MaintenanceModel maintenance;

  const MaintenanceNextServiceCard({super.key, required this.maintenance});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final hasDate = maintenance.nextDate != null;
    final hasMileage = maintenance.nextOdometer != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm_outlined, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                context.l10n.maintenance_next_review,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              if (hasDate)
                _NextRow(
                  label: context.l10n.maintenance_next_date_label,
                  value: maintenance.nextDate!.formattedDate,
                ),
              if (hasDate && hasMileage) const SizedBox(height: 8),
              if (hasMileage)
                _NextRow(
                  label: context.l10n.maintenance_next_odometer_label,
                  value:
                      '${numberFormat.format(maintenance.nextOdometer)} km',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextRow extends StatelessWidget {
  final String label;
  final String value;

  const _NextRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textOnDarkSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textOnDarkPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
