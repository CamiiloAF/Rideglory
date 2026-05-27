import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/filter_sheet/filter_radio_indicator.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/filter_sheet/filter_section_label.dart';

class FilterDateRangeSection extends StatelessWidget {
  final MaintenanceDateRange? selected;
  final ValueChanged<MaintenanceDateRange?> onChanged;

  const FilterDateRangeSection({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (MaintenanceDateRange.thisMonth, context.l10n.maintenance_filter_date_this_month),
      (MaintenanceDateRange.last3Months, context.l10n.maintenance_filter_date_last_3_months),
      (MaintenanceDateRange.lastYear, context.l10n.maintenance_filter_date_last_year),
      (MaintenanceDateRange.custom, context.l10n.maintenance_filter_date_custom),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterSectionLabel(context.l10n.maintenance_filter_date_range_label),
          const SizedBox(height: 4),
          ...options.map((entry) {
            final (range, label) = entry;
            final isSelected = selected == range;
            return GestureDetector(
              onTap: () => onChanged(isSelected ? null : range),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textOnDarkPrimary,
                      ),
                    ),
                    FilterRadioIndicator(isSelected: isSelected),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
