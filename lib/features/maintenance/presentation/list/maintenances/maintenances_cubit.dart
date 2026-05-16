import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_list_summary.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenance_list_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters.dart';

class MaintenancesCubit extends Cubit<ResultState<List<MaintenanceModel>>> {
  MaintenancesCubit(this._getMaintenancesUseCase)
    : super(const ResultState.initial());

  final GetMaintenanceListUseCase _getMaintenancesUseCase;
  List<MaintenanceModel> _allMaintenances = [];
  Map<String, MaintenanceListSummary> _summariesByVehicleId = {};
  MaintenanceFilters _filters = const MaintenanceFilters();
  String _searchQuery = '';

  MaintenanceFilters get filters => _filters;
  String get searchQuery => _searchQuery;

  void setInitialVehicleFilter(String vehicleId) {
    _filters = MaintenanceFilters(vehicleIds: [vehicleId]);
  }

  MaintenanceListSummary? summaryForHeader() {
    if (_filters.vehicleIds.length != 1) return null;
    return _summariesByVehicleId[_filters.vehicleIds.first];
  }

  Future<void> fetchMaintenances() async {
    emit(const ResultState.loading());
    final (startDate, endDate) = _filters.dateWindow;
    final result = await _getMaintenancesUseCase.execute(
      types: _filters.types.isEmpty ? null : _filters.types,
      startDate: startDate,
      endDate: endDate,
    );

    result.fold((error) => emit(ResultState.error(error: error)), (aggregate) {
      _allMaintenances = aggregate.items;
      _summariesByVehicleId = Map<String, MaintenanceListSummary>.from(
        aggregate.summariesByVehicleId,
      );
      _applyClientFiltersAndEmit();
    });
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyClientFiltersAndEmit();
  }

  Future<void> updateFilters(MaintenanceFilters filters) async {
    final previousTypes = _filters.types;
    final previousDateRange = _filters.dateRange;
    final previousCustomStart = _filters.customStartDate;
    final previousCustomEnd = _filters.customEndDate;

    _filters = filters;

    final serverFiltersChanged =
        previousTypes != filters.types ||
        previousDateRange != filters.dateRange ||
        previousCustomStart != filters.customStartDate ||
        previousCustomEnd != filters.customEndDate;

    if (serverFiltersChanged) {
      await fetchMaintenances();
    } else {
      _applyClientFiltersAndEmit();
    }
  }

  void addMaintenanceLocally(MaintenanceModel maintenance) {
    _allMaintenances = [..._allMaintenances, maintenance];
    final vid = maintenance.vehicleId;
    if (vid != null) _summariesByVehicleId.remove(vid);
    _applyClientFiltersAndEmit();
  }

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
      final vid = updatedMaintenance.vehicleId;
      if (vid != null) _summariesByVehicleId.remove(vid);
      _applyClientFiltersAndEmit();
    }
  }

  void deleteMaintenanceLocally(String maintenanceId) {
    String? affectedVehicleId;
    for (final maintenance in _allMaintenances) {
      if (maintenance.id == maintenanceId) {
        affectedVehicleId = maintenance.vehicleId;
        break;
      }
    }
    _allMaintenances = _allMaintenances
        .where((m) => m.id != maintenanceId)
        .toList();
    if (affectedVehicleId != null) {
      _summariesByVehicleId.remove(affectedVehicleId);
    }
    _applyClientFiltersAndEmit();
  }

  void _applyClientFiltersAndEmit() {
    var filtered = List<MaintenanceModel>.from(_allMaintenances);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((m) => m.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

    if (_filters.vehicleIds.isNotEmpty) {
      filtered = filtered
          .where(
            (m) =>
                m.vehicleId != null &&
                _filters.vehicleIds.contains(m.vehicleId),
          )
          .toList();
    }

    if (_filters.statusFilter != MaintenanceStatusFilter.all) {
      final now = DateTime.now();
      filtered = filtered.where((maintenance) {
        final next = maintenance.nextMaintenanceDate;
        switch (_filters.statusFilter) {
          case MaintenanceStatusFilter.overdue:
            return next != null && next.isBefore(now);
          case MaintenanceStatusFilter.upcoming:
            if (next == null) return false;
            final daysUntil = next.difference(now).inDays;
            return daysUntil >= 0 && daysUntil <= 30;
          case MaintenanceStatusFilter.onTrack:
            return next == null || next.difference(now).inDays > 30;
          case MaintenanceStatusFilter.all:
            return true;
        }
      }).toList();
    }

    switch (_filters.sortBy) {
      case MaintenanceSortOption.nextMaintenance:
        filtered.sort((a, b) {
          if (a.nextMaintenanceDate != null && b.nextMaintenanceDate == null) {
            return -1;
          }
          if (a.nextMaintenanceDate == null && b.nextMaintenanceDate != null) {
            return 1;
          }
          if (a.nextMaintenanceDate != null && b.nextMaintenanceDate != null) {
            return a.nextMaintenanceDate!.compareTo(b.nextMaintenanceDate!);
          }
          return b.date.compareTo(a.date);
        });
      case MaintenanceSortOption.date:
        filtered.sort((a, b) => b.date.compareTo(a.date));
      case MaintenanceSortOption.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    if (_allMaintenances.isEmpty) {
      emit(const ResultState.empty());
    } else {
      emit(ResultState.data(data: filtered));
    }
  }
}
