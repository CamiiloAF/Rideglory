import 'package:flutter/material.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

enum MaintenanceStatusFilter { all, overdue, upcoming, onTrack }

enum MaintenanceDateRange { thisMonth, last3Months, lastYear, custom }

enum MaintenanceSortOption { nextMaintenance, date, name }

class MaintenanceFilters {
  final String? searchQuery;
  final List<MaintenanceType> types;
  final List<String> vehicleIds;
  final MaintenanceStatusFilter statusFilter;
  final MaintenanceDateRange? dateRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final MaintenanceSortOption sortBy;

  const MaintenanceFilters({
    this.searchQuery,
    this.types = const [],
    this.vehicleIds = const [],
    this.statusFilter = MaintenanceStatusFilter.all,
    this.dateRange,
    this.customStartDate,
    this.customEndDate,
    this.sortBy = MaintenanceSortOption.nextMaintenance,
  });

  /// Returns the [startDate, endDate] pair derived from [dateRange].
  (DateTime?, DateTime?) get dateWindow {
    final now = DateTime.now();
    switch (dateRange) {
      case MaintenanceDateRange.thisMonth:
        return (DateTime(now.year, now.month, 1), now);
      case MaintenanceDateRange.last3Months:
        return (DateTime(now.year, now.month - 3, now.day), now);
      case MaintenanceDateRange.lastYear:
        return (DateTime(now.year - 1, now.month, now.day), now);
      case MaintenanceDateRange.custom:
        return (customStartDate, customEndDate);
      case null:
        return (null, null);
    }
  }

  MaintenanceFilters copyWith({
    String? searchQuery,
    List<MaintenanceType>? types,
    List<String>? vehicleIds,
    MaintenanceStatusFilter? statusFilter,
    MaintenanceDateRange? Function()? dateRange,
    DateTime? customStartDate,
    DateTime? customEndDate,
    MaintenanceSortOption? sortBy,
  }) {
    return MaintenanceFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      types: types ?? this.types,
      vehicleIds: vehicleIds ?? this.vehicleIds,
      statusFilter: statusFilter ?? this.statusFilter,
      dateRange: dateRange != null ? dateRange() : this.dateRange,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters =>
      (searchQuery?.isNotEmpty ?? false) ||
      types.isNotEmpty ||
      vehicleIds.isNotEmpty ||
      statusFilter != MaintenanceStatusFilter.all ||
      dateRange != null;

  int get activeFilterCount {
    int count = 0;
    if (searchQuery?.isNotEmpty ?? false) count++;
    if (types.isNotEmpty) count++;
    if (vehicleIds.isNotEmpty) count++;
    if (statusFilter != MaintenanceStatusFilter.all) count++;
    if (dateRange != null) count++;
    return count;
  }
}

extension MaintenanceSortOptionExt on MaintenanceSortOption {
  String label(BuildContext context) {
    switch (this) {
      case MaintenanceSortOption.nextMaintenance:
        return context.l10n.maintenance_sortByNextMaintenance;
      case MaintenanceSortOption.date:
        return context.l10n.maintenance_sortByDate;
      case MaintenanceSortOption.name:
        return context.l10n.maintenance_sortByName;
    }
  }
}
