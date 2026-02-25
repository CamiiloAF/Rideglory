import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenance_list_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters.dart';

class MaintenancesCubit extends Cubit<ResultState<List<MaintenanceModel>>> {
  MaintenancesCubit(this._getMaintenancesUseCase)
    : super(const ResultState.initial());

  final GetMaintenanceListUseCase _getMaintenancesUseCase;
  List<MaintenanceModel> _allMaintenances = [];
  MaintenanceFilters _filters = const MaintenanceFilters();
  String _searchQuery = '';

  MaintenanceFilters get filters => _filters;
  String get searchQuery => _searchQuery;

  Future<void> fetchMaintenances() async {
    emit(const ResultState.loading());
    final result = await _getMaintenancesUseCase.execute();

    result.fold((error) => emit(ResultState.error(error: error)), (
      maintenances,
    ) {
      _allMaintenances = maintenances;
      _applyFiltersAndEmit();
    });
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndEmit();
  }

  void updateFilters(MaintenanceFilters filters) {
    _filters = filters;
    _applyFiltersAndEmit();
  }

  /// Add a new maintenance to the local list without refetching from Firebase
  void addMaintenanceLocally(MaintenanceModel maintenance) {
    _allMaintenances = [..._allMaintenances, maintenance];
    _applyFiltersAndEmit();
  }

  /// Update an existing maintenance in the local list without refetching from Firebase
  void updateMaintenanceLocally(MaintenanceModel updatedMaintenance) {
    final index = _allMaintenances.indexWhere(
      (m) => m.id == updatedMaintenance.id,
    );
    if (index != -1) {
      _allMaintenances = [
        ..._allMaintenances.sublist(0, index),
        updatedMaintenance,
        ..._allMaintenances.sublist(index + 1),
      ];
      _applyFiltersAndEmit();
    }
  }

  /// Remove a maintenance from the local list without refetching from Firebase
  void deleteMaintenanceLocally(String maintenanceId) {
    _allMaintenances = _allMaintenances
        .where((m) => m.id != maintenanceId)
        .toList();
    _applyFiltersAndEmit();
  }

  void _applyFiltersAndEmit() {
    var filtered = List<MaintenanceModel>.from(_allMaintenances);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        return m.name.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Filter by types
    if (_filters.types.isNotEmpty) {
      filtered = filtered
          .where((m) => _filters.types.contains(m.type))
          .toList();
    }

    // Filter by vehicles
    if (_filters.vehicleIds.isNotEmpty) {
      filtered = filtered
          .where(
            (m) =>
                m.vehicleId != null &&
                _filters.vehicleIds.contains(m.vehicleId),
          )
          .toList();
    }

    // Filter by date range
    if (_filters.startDate != null) {
      filtered = filtered
          .where(
            (m) =>
                m.date.isAfter(_filters.startDate!) ||
                m.date.isAtSameMomentAs(_filters.startDate!),
          )
          .toList();
    }
    if (_filters.endDate != null) {
      filtered = filtered
          .where(
            (m) =>
                m.date.isBefore(_filters.endDate!.add(const Duration(days: 1))),
          )
          .toList();
    }

    // Filter urgent only
    if (_filters.showUrgentOnly == true) {
      final now = DateTime.now();
      filtered = filtered.where((m) {
        // Must have alerts enabled
        if (!m.receiveAlert) return false;

        if (m.nextMaintenanceDate != null) {
          final daysUntil = m.nextMaintenanceDate!.difference(now).inDays;
          // Urgent if overdue (negative) or within 7 days (0-6 days)
          return daysUntil <= 7;
        }
        return false;
      }).toList();
    }

    // Sort
    switch (_filters.sortBy) {
      case MaintenanceSortOption.nextMaintenance:
        filtered.sort((a, b) {
          // Items with next maintenance date come first
          if (a.nextMaintenanceDate != null && b.nextMaintenanceDate == null) {
            return -1;
          }
          if (a.nextMaintenanceDate == null && b.nextMaintenanceDate != null) {
            return 1;
          }
          if (a.nextMaintenanceDate != null && b.nextMaintenanceDate != null) {
            return a.nextMaintenanceDate!.compareTo(b.nextMaintenanceDate!);
          }
          // If both null, sort by date
          return b.date.compareTo(a.date);
        });
        break;
      case MaintenanceSortOption.date:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case MaintenanceSortOption.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    // Only emit empty if there are no maintenances at all
    // If there are maintenances but filters return empty, emit data with empty list
    if (_allMaintenances.isEmpty) {
      emit(const ResultState.empty());
    } else {
      emit(ResultState.data(data: filtered));
    }
  }
}
