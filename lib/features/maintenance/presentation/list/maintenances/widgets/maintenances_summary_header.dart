import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
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
    final sorted = [...maintenances]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }

  DateTime? _nextFromList() {
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
    final locale = Localizations.localeOf(context);
    final dateShort = DateFormat.MMMd(locale.toString());
    final numberFormat = NumberFormat('#,###');
    final l10n = context.l10n;

    final lastFromList = _lastFromList();
    final lastDate = maintenanceSummary?.lastServiceDate ?? lastFromList?.date;
    final lastMileage =
        maintenanceSummary?.lastServiceMileage ?? lastFromList?.maintanceMileage;
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
                  label: l10n.maintenance_lastService,
                  value: lastDate != null ? dateShort.format(lastDate) : '—',
                  subtitle: lastMileage != null
                      ? '${numberFormat.format(lastMileage)} ${l10n.maintenance_km}'
                      : null,
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: MaintenanceSummaryCard(
                  icon: Icons.event_repeat_outlined,
                  label: l10n.maintenance_nextService,
                  value: nextDate != null
                      ? dateShort.format(nextDate)
                      : l10n.maintenance_estimatedDate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
