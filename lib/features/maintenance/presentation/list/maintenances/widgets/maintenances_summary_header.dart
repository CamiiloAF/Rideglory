import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

class MaintenancesSummaryHeader extends StatelessWidget {
  final List<MaintenanceModel> maintenances;

  const MaintenancesSummaryHeader({super.key, required this.maintenances});

  MaintenanceModel? _getLastService() {
    if (maintenances.isEmpty) return null;
    final sorted = [...maintenances]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }

  DateTime? _getNextServiceDate() {
    final now = DateTime.now();
    final candidates =
        maintenances
            .map((m) => m.nextMaintenanceDate)
            .whereType<DateTime>()
            .where((d) => d.isAfter(now))
            .toList()
          ..sort();
    return candidates.isEmpty ? null : candidates.first;
  }

  @override
  Widget build(BuildContext context) {
    final dateShort = DateFormat('MMM dd');
    final numberFormat = NumberFormat('#,###');

    final lastService = _getLastService();
    final nextServiceDate = _getNextServiceDate();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Last service',
                  value: lastService != null
                      ? dateShort.format(lastService.date)
                      : '—',
                  subtitle: lastService != null
                      ? '${numberFormat.format(lastService.maintanceMileage)} km'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.event_repeat_outlined,
                  label: 'Next service',
                  value: nextServiceDate != null
                      ? dateShort.format(nextServiceDate)
                      : 'Estimated',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: context.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: context.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
