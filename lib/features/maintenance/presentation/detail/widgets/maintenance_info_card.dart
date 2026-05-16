import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

class MaintenanceInfoCard extends StatelessWidget {
  final MaintenanceModel maintenance;

  const MaintenanceInfoCard({super.key, required this.maintenance});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    final rows = <_InfoRow>[
      _InfoRow(
        label: context.l10n.maintenance_service_date,
        value: maintenance.date.formattedDate,
        isAccent: false,
      ),
      _InfoRow(
        label: context.l10n.maintenance_odometer_km,
        value: '${numberFormat.format(maintenance.maintanceMileage)} km',
        isAccent: false,
      ),
      if (maintenance.cost != null)
        _InfoRow(
          label: context.l10n.maintenance_totalCost,
          value: currencyFormat.format(maintenance.cost),
          isAccent: true,
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.maintenance_service_info,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textOnDarkPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            return Column(
              children: [
                if (entry.key > 0)
                  const Divider(
                    color: AppColors.darkBorderPrimary,
                    height: 1,
                    indent: 0,
                    endIndent: 0,
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    isLast ? 12 : 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.value.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnDarkSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        entry.value.value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: entry.value.isAccent
                              ? AppColors.primary
                              : AppColors.textOnDarkPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool isAccent;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isAccent,
  });
}
