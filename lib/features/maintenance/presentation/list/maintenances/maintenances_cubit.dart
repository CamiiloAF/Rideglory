import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_list_summary.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenance_list_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/widgets/maintenance_filters.dart';

class MaintenancesCubit extends Cubit<ResultState<List<MaintenanceModel>>> {
  MaintenancesCubit(this._getMaintenancesUseCase, this._analytics)
    : super(const ResultState.initial());

  final GetMaintenanceListUseCase _getMaintenancesUseCase;
  final AnalyticsService _analytics;
  List<MaintenanceModel> _allMaintenances = [];
  Map<String, MaintenanceListSummary> _summariesByVehicleId = {};
  MaintenanceFilters _filters = const MaintenanceFilters();
  String _searchQuery = '';

  /// Current vehicle mileage for status calculation.
  /// Set by the page when it has vehicle context.
  int _currentVehicleMileage = 0;

  MaintenanceFilters get filters => _filters;
  String get searchQuery => _searchQuery;

  void setCurrentVehicleMileage(int mileage) {
    _currentVehicleMileage = mileage;
    // Only re-filter if data is already loaded; otherwise fetchMaintenances will
    // pick up the correct mileage when it resolves.
    if (_allMaintenances.isNotEmpty) {
      _applyClientFiltersAndEmit();
    }
  }

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
    // Si el filtro tiene exactamente 1 vehículo, consultamos solo ese endpoint
    // en vez de iterar todos los vehículos del usuario.
    final scopedVehicleId =
        _filters.vehicleIds.length == 1 ? _filters.vehicleIds.first : null;
    final result = await _getMaintenancesUseCase.execute(
      vehicleId: scopedVehicleId,
      types: _filters.types.isEmpty ? null : _filters.types,
      startDate: startDate,
      endDate: endDate,
    );

    result.fold((error) => emit(ResultState.error(error: error)), (aggregate) {
      _allMaintenances = aggregate.items;
      _summariesByVehicleId = Map<String, MaintenanceListSummary>.from(
        aggregate.summariesByVehicleId,
      );
      _analytics
          .logEvent(AnalyticsEvents.maintenanceHistoryViewed, {
            AnalyticsParams.resultCount: aggregate.items.length,
          })
          .ignore();
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
    final vehicleId = maintenance.vehicleId;
    if (vehicleId != null) _summariesByVehicleId.remove(vehicleId);
    _applyClientFiltersAndEmit();
  }

  /// Inserts multiple records locally (e.g. completed + auto-created scheduled).
  void addMaintenancesLocally(List<MaintenanceModel> maintenances) {
    _allMaintenances = [..._allMaintenances, ...maintenances];
    for (final maintenance in maintenances) {
      final vehicleId = maintenance.vehicleId;
      if (vehicleId != null) _summariesByVehicleId.remove(vehicleId);
    }
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
      final vehicleId = updatedMaintenance.vehicleId;
      if (vehicleId != null) _summariesByVehicleId.remove(vehicleId);
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

    if (_filters.types.isNotEmpty) {
      filtered = filtered.where((m) => _filters.types.contains(m.type)).toList();
    }

    // Status filter alineado con las secciones del listado:
    // - "Vencidos" (overdue): programados vencidos.
    // - "Próximos" (next): TODO programado no vencido (next + upToDate).
    // - "Al día" (upToDate): solo el historial de completados.
    if (_filters.statusFilter != MaintenanceStatusFilter.all) {
      filtered = filtered.where((maintenance) {
        if (maintenance.mode == MaintenanceMode.completed) {
          // Un completado representa el historial "al día" del vehículo.
          return _filters.statusFilter == MaintenanceStatusFilter.upToDate;
        }
        final status = MaintenanceModel.calculateStatus(
          maintenance,
          _currentVehicleMileage,
        );
        switch (_filters.statusFilter) {
          case MaintenanceStatusFilter.overdue:
            return status == MaintenanceStatus.overdue;
          case MaintenanceStatusFilter.next:
            return status == MaintenanceStatus.next ||
                status == MaintenanceStatus.upToDate;
          case MaintenanceStatusFilter.upToDate:
            // Los programados ya no se consideran "al día".
            return false;
          case MaintenanceStatusFilter.all:
            return true;
        }
      }).toList();
    }

    // Sort by urgency: overdue → next → upToDate → completed (by serviceDate desc)
    filtered.sort(_compareByUrgency);

    if (_allMaintenances.isEmpty) {
      emit(const ResultState.empty());
    } else {
      emit(ResultState.data(data: filtered));
    }
  }

  int _compareByUrgency(MaintenanceModel a, MaintenanceModel b) {
    final statusA = a.mode == MaintenanceMode.completed
        ? null
        : MaintenanceModel.calculateStatus(a, _currentVehicleMileage);
    final statusB = b.mode == MaintenanceMode.completed
        ? null
        : MaintenanceModel.calculateStatus(b, _currentVehicleMileage);

    final rankA = _statusRank(a.mode, statusA);
    final rankB = _statusRank(b.mode, statusB);

    if (rankA != rankB) return rankA.compareTo(rankB);

    // Within same urgency rank, most recent first
    final dateA = a.serviceDate ?? a.nextDate ?? a.createdDate ?? DateTime(0);
    final dateB = b.serviceDate ?? b.nextDate ?? b.createdDate ?? DateTime(0);
    return dateB.compareTo(dateA);
  }

  static int _statusRank(MaintenanceMode mode, MaintenanceStatus? status) {
    if (mode == MaintenanceMode.scheduled) {
      switch (status) {
        case MaintenanceStatus.overdue:
          return 0;
        case MaintenanceStatus.next:
          return 1;
        case MaintenanceStatus.upToDate:
        case null:
          return 2;
      }
    }
    // completed always last
    return 3;
  }
}
