import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/shared/widgets/filter/filter_section_label.dart';
import 'package:rideglory/shared/widgets/filter/filter_type_chip.dart';

class FilterTypeSection extends StatelessWidget {
  final List<MaintenanceType> selectedTypes;
  final ValueChanged<List<MaintenanceType>> onChanged;

  const FilterTypeSection({
    super.key,
    required this.selectedTypes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterSectionLabel(context.l10n.maintenance_filter_type_label),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MaintenanceType.values.map((type) {
              final isSelected = selectedTypes.contains(type);
              return FilterTypeChip(
                label: type.label,
                isSelected: isSelected,
                onTap: () {
                  final updated = List<MaintenanceType>.from(selectedTypes);
                  if (isSelected) {
                    updated.remove(type);
                  } else {
                    updated.add(type);
                  }
                  onChanged(updated);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
