import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/filter_section_title.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    context.l10n.maintenance_filters,
                    style: context.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (_filters.hasActiveFilters)
                  AppButton(
                    label: context.l10n.clear,
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
                  FilterSectionTitle(context.l10n.maintenance_sortBy),
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MaintenanceSortOption.values.map((option) {
                      final isSelected = _filters.sortBy == option;
                      return FilterChip(
                        label: Text(
                          option.label(context),
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
                  AppSpacing.gapXxl,

                  // Maintenance types
                  FilterSectionTitle(context.l10n.maintenance_maintenanceTypes),
                  AppSpacing.gapSm,
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
                  AppSpacing.gapXxl,

                  // Urgent only
                  SwitchListTile(
                    title: Text(
                      context.l10n.maintenance_urgentOnly,
                      style: TextStyle(color: context.colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      context.l10n.maintenance_urgentOnlyDescription,
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
                  AppSpacing.gapLg,

                  // Date range
                  FilterSectionTitle(context.l10n.maintenance_dateRange),
                  AppSpacing.gapSm,
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
                                : context.l10n.maintenance_startDate,
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
                      AppSpacing.hGapMd,
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
                                : context.l10n.maintenance_endDate,
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
                    label: context.l10n.cancel,
                    variant: AppButtonVariant.primary,
                    style: AppButtonStyle.outlined,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: AppButton(
                    label: context.l10n.apply,
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
