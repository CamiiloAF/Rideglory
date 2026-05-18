import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

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
                child: _StatBox(
                  value: maintenances.length.toString(),
                  label: context.l10n.maintenance_services_count,
                  valueFontSize: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatBox(
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

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final double valueFontSize;

  const _StatBox({
    required this.value,
    required this.label,
    required this.valueFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textOnDarkSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
