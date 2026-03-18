import 'package:flutter/material.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/filter_section_title.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/design_system/design_system.dart';

class MaintenanceFiltersBottomSheet extends StatefulWidget {
  final MaintenanceFilters initialFilters;
  final List<VehicleModel> availableVehicles;

  const MaintenanceFiltersBottomSheet({
    super.key,
    required this.initialFilters,
    required this.availableVehicles,
  });

  @override
  State<MaintenanceFiltersBottomSheet> createState() =>
      _MaintenanceFiltersBottomSheetState();
}

class _MaintenanceFiltersBottomSheetState
    extends State<MaintenanceFiltersBottomSheet> {
  late MaintenanceFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    MaintenanceStrings.filters,
                    style: context.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (_filters.hasActiveFilters)
                  AppButton(
                    label: AppStrings.clear,
                    variant: AppButtonVariant.primary,
                    style: AppButtonStyle.text,
                    isFullWidth: false,
                    onPressed: () {
                      setState(() {
                        _filters = const MaintenanceFilters().copyWith(
                          vehicleIds: _filters.vehicleIds,
                        );
                      });
                    },
                  ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort by
                  const FilterSectionTitle(MaintenanceStrings.sortBy),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MaintenanceSortOption.values.map((option) {
                      final isSelected = _filters.sortBy == option;
                      return FilterChip(
                        label: Text(
                          option.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: context.colorScheme.primary,
                        backgroundColor: context.colorScheme.surfaceContainerHighest,
                        checkmarkColor: Colors.white,
                        side:
                            BorderSide(color: context.colorScheme.outlineVariant),
                        onSelected: (selected) {
                          setState(() {
                            _filters = _filters.copyWith(sortBy: option);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),

                  // Maintenance types
                  const FilterSectionTitle(MaintenanceStrings.maintenanceTypes),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MaintenanceType.values.map((type) {
                      final isSelected = _filters.types.contains(type);
                      return FilterChip(
                        label: Text(
                          type.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: context.colorScheme.primary,
                        backgroundColor: context.colorScheme.surfaceContainerHighest,
                        checkmarkColor: Colors.white,
                        side:
                            BorderSide(color: context.colorScheme.outlineVariant),
                        onSelected: (selected) {
                          setState(() {
                            final newTypes = List<MaintenanceType>.from(
                              _filters.types,
                            );
                            if (selected) {
                              newTypes.add(type);
                            } else {
                              newTypes.remove(type);
                            }
                            _filters = _filters.copyWith(types: newTypes);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),

                  // Urgent only
                  SwitchListTile(
                    title: Text(
                      MaintenanceStrings.urgentOnly,
                      style: TextStyle(color: context.colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      MaintenanceStrings.urgentOnlyDescription,
                      style: TextStyle(color: context.colorScheme.onSurfaceVariant),
                    ),
                    value: _filters.showUrgentOnly ?? false,
                    onChanged: (value) {
                      setState(() {
                        _filters = _filters.copyWith(
                          showUrgentOnly: () => value,
                        );
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  SizedBox(height: 16),

                  // Date range
                  const FilterSectionTitle(MaintenanceStrings.dateRange),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: context.colorScheme.primary,
                          ),
                          label: Text(
                            _filters.startDate != null
                                ? _filters.startDate!.toFormattedString()
                                : MaintenanceStrings.startDate,
                            style: TextStyle(
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: context.colorScheme.outlineVariant,
                            ),
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _filters.startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _filters = _filters.copyWith(startDate: date);
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: context.colorScheme.primary,
                          ),
                          label: Text(
                            _filters.endDate != null
                                ? _filters.endDate!.toFormattedString()
                                : MaintenanceStrings.endDate,
                            style: TextStyle(
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: context.colorScheme.outlineVariant,
                            ),
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _filters.endDate ?? DateTime.now(),
                              firstDate: _filters.startDate ?? DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _filters = _filters.copyWith(endDate: date);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              border: Border(top: BorderSide(color: context.colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: AppStrings.cancel,
                    variant: AppButtonVariant.primary,
                    style: AppButtonStyle.outlined,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: AppStrings.apply,
                    variant: AppButtonVariant.primary,
                    onPressed: () => Navigator.pop(context, _filters),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
