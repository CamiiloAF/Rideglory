import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/filter_sheet/filter_cta_bar.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/filter_sheet/filter_date_range_section.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/filter_sheet/filter_divider.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/filter_sheet/filter_handle_bar.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/filter_sheet/filter_panel_header.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/filter_sheet/filter_status_section.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/filter_sheet/filter_type_section.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

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

  void _clearAll() {
    setState(() {
      _filters = const MaintenanceFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.darkBorderPrimary),
          left: BorderSide(color: AppColors.darkBorderPrimary),
          right: BorderSide(color: AppColors.darkBorderPrimary),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FilterHandleBar(),
          FilterPanelHeader(
            hasActiveFilters: _filters.hasActiveFilters,
            onClearAll: _clearAll,
          ),
          const FilterDivider(),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  FilterTypeSection(
                    selectedTypes: _filters.types,
                    onChanged: (types) =>
                        setState(() => _filters = _filters.copyWith(types: types)),
                  ),
                  const FilterDivider(),
                  FilterStatusSection(
                    selected: _filters.statusFilter,
                    onChanged: (status) => setState(
                      () => _filters = _filters.copyWith(statusFilter: status),
                    ),
                  ),
                  const FilterDivider(),
                  FilterDateRangeSection(
                    selected: _filters.dateRange,
                    onChanged: (range) => setState(
                      () => _filters = _filters.copyWith(
                        dateRange: () => range,
                        customStartDate: null,
                        customEndDate: null,
                      ),
                    ),
                  ),
                  const FilterDivider(),
                ],
              ),
            ),
          ),
          FilterCtaBar(
            activeFilterCount: _filters.activeFilterCount,
            onClear: _clearAll,
            onApply: () => context.pop(_filters),
          ),
        ],
      ),
    );
  }
}
