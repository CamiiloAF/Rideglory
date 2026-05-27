import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenance_stat_box.dart';

class MaintenanceSummaryWidget extends StatelessWidget {
  final List<MaintenanceModel> maintenances;

  const MaintenanceSummaryWidget({super.key, required this.maintenances});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');
    final totalCost = maintenances.fold<double>(
      0,
      (sum, m) => sum + (m.cost ?? 0),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.maintenance_summary_title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textOnDarkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.build_outlined,
                color: AppColors.primary,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.darkBorderPrimary, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MaintenanceStatBox(
                  value: maintenances.length.toString(),
                  label: context.l10n.maintenance_services_count,
                  valueFontSize: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MaintenanceStatBox(
                  value: '\$${currencyFormat.format(totalCost)}',
                  label: context.l10n.maintenance_total_spent,
                  valueFontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
