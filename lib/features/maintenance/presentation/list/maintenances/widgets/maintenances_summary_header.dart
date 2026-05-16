import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_list_summary.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenance_summary_card.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaintenancesSummaryHeader extends StatelessWidget {
  const MaintenancesSummaryHeader({
    super.key,
    required this.maintenances,
    this.maintenanceSummary,
  });

  final List<MaintenanceModel> maintenances;
  final MaintenanceListSummary? maintenanceSummary;

  MaintenanceModel? _lastFromList() {
    if (maintenances.isEmpty) return null;
    final completed = maintenances
        .where((m) => m.mode == MaintenanceMode.completed)
        .toList();
    if (completed.isEmpty) return null;
    completed.sort((a, b) {
      final dateA = a.serviceDate ?? a.createdDate ?? DateTime(0);
      final dateB = b.serviceDate ?? b.createdDate ?? DateTime(0);
      return dateB.compareTo(dateA);
    });
    return completed.first;
  }

  DateTime? _nextFromList() {
    final now = DateTime.now();
    final candidates = maintenances
        .map((m) => m.nextDate)
        .whereType<DateTime>()
        .where((d) => d.isAfter(now))
        .toList()
      ..sort();
    return candidates.isEmpty ? null : candidates.first;
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');

    final lastFromList = _lastFromList();
    final lastService =
        maintenanceSummary?.lastServiceDate ?? lastFromList?.serviceDate;
    final nextDate = maintenanceSummary?.nextServiceDate ?? _nextFromList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: MaintenanceSummaryCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Last service',
                  value: lastService?.formattedDate ?? '—',
                  subtitle: lastService != null
                      ? '${numberFormat.format(maintenanceSummary?.lastServiceMileage)} km'
                      : null,
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: MaintenanceSummaryCard(
                  icon: Icons.event_repeat_outlined,
                  label: 'Next service',
                  value: nextDate?.formattedDate ?? 'Estimated',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
