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
import 'package:rideglory/shared/widgets/form/app_button.dart';

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
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
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
              color: AppColors.darkBorder,
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
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ),
                if (_filters.hasActiveFilters)
                  AppButton(
                    label: AppStrings.clear,
                    variant: AppButtonVariant.text,
                    isFullWidth: false,
                    onPressed: () {
                      setState(() {
                        _filters = MaintenanceFilters().copyWith(
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
                  FilterSectionTitle(MaintenanceStrings.sortBy),
                  const SizedBox(height: 8),
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
                                : AppColors.darkTextSecondary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.darkSurfaceHighest,
                        checkmarkColor: Colors.white,
                        side: BorderSide(color: AppColors.darkBorder),
                        onSelected: (selected) {
                          setState(() {
                            _filters = _filters.copyWith(sortBy: option);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Maintenance types
                  FilterSectionTitle(MaintenanceStrings.maintenanceTypes),
                  const SizedBox(height: 8),
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
                                : AppColors.darkTextSecondary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.darkSurfaceHighest,
                        checkmarkColor: Colors.white,
                        side: BorderSide(color: AppColors.darkBorder),
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
                  const SizedBox(height: 24),

                  // Urgent only
                  SwitchListTile(
                    title: Text(
                      MaintenanceStrings.urgentOnly,
                      style: const TextStyle(color: AppColors.darkTextPrimary),
                    ),
                    subtitle: const Text(
                      MaintenanceStrings.urgentOnlyDescription,
                      style: TextStyle(color: AppColors.darkTextSecondary),
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
                  const SizedBox(height: 16),

                  // Date range
                  FilterSectionTitle(MaintenanceStrings.dateRange),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            _filters.startDate != null
                                ? _filters.startDate!.toFormattedString()
                                : MaintenanceStrings.startDate,
                            style: const TextStyle(
                              color: AppColors.darkTextPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.darkBorder),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            _filters.endDate != null
                                ? _filters.endDate!.toFormattedString()
                                : MaintenanceStrings.endDate,
                            style: const TextStyle(
                              color: AppColors.darkTextPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.darkBorder),
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
              color: AppColors.darkSurface,
              border: Border(top: BorderSide(color: AppColors.darkBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: AppStrings.cancel,
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
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
