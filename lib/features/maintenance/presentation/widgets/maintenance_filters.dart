import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_strings.dart';

class MaintenanceFilters {
  final String? searchQuery;
  final List<MaintenanceType> types;
  final List<String> vehicleIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? showUrgentOnly;
  final MaintenanceSortOption sortBy;

  const MaintenanceFilters({
    this.searchQuery,
    this.types = const [],
    this.vehicleIds = const [],
    this.startDate,
    this.endDate,
    this.showUrgentOnly,
    this.sortBy = MaintenanceSortOption.nextMaintenance,
  });

  MaintenanceFilters copyWith({
    String? searchQuery,
    List<MaintenanceType>? types,
    List<String>? vehicleIds,
    DateTime? startDate,
    DateTime? endDate,
    bool Function()? showUrgentOnly,
    MaintenanceSortOption? sortBy,
  }) {
    return MaintenanceFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      types: types ?? this.types,
      vehicleIds: vehicleIds ?? this.vehicleIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      showUrgentOnly: showUrgentOnly != null
          ? showUrgentOnly()
          : this.showUrgentOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters =>
      (searchQuery?.isNotEmpty ?? false) ||
      types.isNotEmpty ||
      vehicleIds.isNotEmpty ||
      startDate != null ||
      endDate != null ||
      showUrgentOnly == true;

  int get activeFilterCount {
    int count = 0;
    if (searchQuery?.isNotEmpty ?? false) count++;
    if (types.isNotEmpty) count++;
    if (vehicleIds.isNotEmpty) count++;
    if (startDate != null || endDate != null) count++;
    if (showUrgentOnly == true) count++;
    return count;
  }
}

enum MaintenanceSortOption { nextMaintenance, date, name }

extension MaintenanceSortOptionExt on MaintenanceSortOption {
  String get label {
    switch (this) {
      case MaintenanceSortOption.nextMaintenance:
        return MaintenanceStrings.sortByNextMaintenance;
      case MaintenanceSortOption.date:
        return MaintenanceStrings.sortByDate;
      case MaintenanceSortOption.name:
        return MaintenanceStrings.sortByName;
    }
  }
}
