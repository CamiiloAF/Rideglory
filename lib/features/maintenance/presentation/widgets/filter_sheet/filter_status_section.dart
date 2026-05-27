import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/filter_sheet/filter_section_label.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/filter_sheet/filter_status_chip.dart';

class FilterStatusSection extends StatelessWidget {
  final MaintenanceStatusFilter selected;
  final ValueChanged<MaintenanceStatusFilter> onChanged;

  const FilterStatusSection({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterSectionLabel(context.l10n.maintenance_filter_status_label),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterStatusChip(
                label: context.l10n.maintenance_filter_status_all,
                textColor: AppColors.textOnDarkSecondary,
                fillColor: AppColors.darkBgSecondary,
                borderColor: AppColors.darkBorderPrimary,
                isSelected: selected == MaintenanceStatusFilter.all,
                onTap: () => onChanged(MaintenanceStatusFilter.all),
              ),
              FilterStatusChip(
                label: context.l10n.maintenance_filter_status_overdue,
                textColor: AppColors.statusError,
                fillColor: AppColors.statusError.withValues(alpha: 0.13),
                borderColor: AppColors.statusError.withValues(alpha: 0.31),
                isSelected: selected == MaintenanceStatusFilter.overdue,
                onTap: () => onChanged(MaintenanceStatusFilter.overdue),
              ),
              FilterStatusChip(
                label: context.l10n.maintenance_filter_status_upcoming,
                // Intentional: statusWarning preserved from prior batch annotation
                textColor: AppColors.statusWarning,
                fillColor: AppColors.statusWarning.withValues(alpha: 0.13),
                borderColor: AppColors.statusWarning.withValues(alpha: 0.31),
                isSelected: selected == MaintenanceStatusFilter.next,
                onTap: () => onChanged(MaintenanceStatusFilter.next),
              ),
              FilterStatusChip(
                label: context.l10n.maintenance_filter_status_on_track,
                // Intentional: statusGreen preserved from prior batch annotation
                textColor: AppColors.statusGreen,
                fillColor: AppColors.statusGreen.withValues(alpha: 0.13),
                borderColor: AppColors.statusGreen.withValues(alpha: 0.31),
                isSelected: selected == MaintenanceStatusFilter.upToDate,
                onTap: () => onChanged(MaintenanceStatusFilter.upToDate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
