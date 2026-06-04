import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/add_maintenance_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_form_fields.dart';

import '../../../domain/use_cases/update_maintenance_use_case.dart';

/// Result state holds the primary saved MaintenanceModel.
/// When auto-creation of a scheduled record occurs, the cubit exposes it
/// via [createdScheduledRecord] for the caller to insert locally.
@injectable
class MaintenanceFormCubit extends Cubit<ResultState<MaintenanceModel>> {
  MaintenanceFormCubit(
    this._addMaintenanceUseCase,
    this._updateMaintenanceUseCase,
    this._analytics,
  ) : super(const ResultState.initial());

  final formKey = GlobalKey<FormBuilderState>();

  final AddMaintenanceUseCase _addMaintenanceUseCase;
  final UpdateMaintenanceUseCase _updateMaintenanceUseCase;
  final AnalyticsService _analytics;

  MaintenanceModel? _editingMaintenance;
  VehicleModel? preselectedVehicle;
  String? userId;
  String? _resolvedVehicleId;
  int? _currentVehicleMileage;
  MaintenanceType? _selectedType;
  MaintenanceMode _mode = MaintenanceMode.completed;

  /// When a completed maintenance auto-creates a scheduled record,
  /// this holds the second record for local insertion by the caller.
  List<MaintenanceModel>? lastSavedRecords;

  bool get isEditing => _editingMaintenance != null;
  MaintenanceModel? get editingMaintenance => _editingMaintenance;
  int? get currentVehicleMileage => _currentVehicleMileage;
  MaintenanceMode get selectedMode => _mode;

  void initialize({
    MaintenanceModel? maintenance,
    VehicleModel? preselectedVehicle,
  }) {
    this.preselectedVehicle = preselectedVehicle;
    _editingMaintenance = maintenance;
    _selectedType = maintenance?.type;
    _mode = maintenance?.mode ?? MaintenanceMode.completed;
    userId = maintenance?.userId;
    _resolvedVehicleId = preselectedVehicle?.id ?? maintenance?.vehicleId;
    lastSavedRecords = null;
    emit(const ResultState.initial());
  }

  void setVehicleId(String? vehicleId) {
    _resolvedVehicleId ??= vehicleId;
  }

  void setCurrentVehicleMileage(int? mileage) {
    _currentVehicleMileage = mileage;
  }

  void updateSelectedType(MaintenanceType type) {
    _selectedType = type;
  }

  void updateMode(MaintenanceMode mode) {
    _mode = mode;
    emit(const ResultState.initial());
  }

  /// Persists [maintenance] to the backend.
  ///
  /// [maintenance] must already be validated and built via [buildMaintenanceToSave]
  /// before calling this method. [nextKmInterval] is the relative km interval read
  /// from the form after [buildMaintenanceToSave] (i.e. after saveAndValidate()).
  Future<void> saveMaintenance(
    MaintenanceModel maintenance, {
    int? nextKmInterval,
  }) async {
    emit(const ResultState.loading());

    if (maintenance.id != null) {
      final result = await _updateMaintenanceUseCase(maintenance);
      result.fold(
        (error) => emit(ResultState.error(error: error)),
        (saved) {
          lastSavedRecords = [saved];
          _analytics
              .logEvent(AnalyticsEvents.maintenanceUpdated, {
                AnalyticsParams.maintenanceType: saved.type.name,
                AnalyticsParams.maintenanceMode: saved.mode ==
                        MaintenanceMode.completed
                    ? AnalyticsParams.maintenanceModeCompleted
                    : AnalyticsParams.maintenanceModeScheduled,
              })
              .ignore();
          emit(ResultState.data(data: saved));
        },
      );
    } else {
      final result = await _addMaintenanceUseCase(
        maintenance,
        nextKmInterval: nextKmInterval,
      );
      result.fold(
        (error) => emit(ResultState.error(error: error)),
        (savedList) {
          lastSavedRecords = savedList;
          final saved = savedList.first;
          _analytics
              .logEvent(AnalyticsEvents.maintenanceAdded, {
                AnalyticsParams.maintenanceType: saved.type.name,
                AnalyticsParams.maintenanceMode: saved.mode ==
                        MaintenanceMode.completed
                    ? AnalyticsParams.maintenanceModeCompleted
                    : AnalyticsParams.maintenanceModeScheduled,
              })
              .ignore();
          emit(ResultState.data(data: saved));
        },
      );
    }
  }

  MaintenanceModel? buildMaintenanceToSave() {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      final formData = formKey.currentState!.value;

      final type =
          (_selectedType ??
          formData[MaintenanceFormFields.type] as MaintenanceType?)!;

      final odometerAtService =
          formData[MaintenanceFormFields.currentMileage] != null &&
              (formData[MaintenanceFormFields.currentMileage] as String).isNotEmpty
          ? int.tryParse(formData[MaintenanceFormFields.currentMileage] as String)
          : _currentVehicleMileage;

      final relativeNextKm = buildNextKmInterval();
      final baseKm = _mode == MaintenanceMode.completed
          ? (odometerAtService ?? _currentVehicleMileage ?? 0)
          : (_currentVehicleMileage ?? 0);
      final nextOdometer = relativeNextKm != null ? baseKm + relativeNextKm : null;

      return MaintenanceModel(
        id: _editingMaintenance?.id,
        vehicleId: _resolvedVehicleId,
        userId: userId,
        type: type,
        mode: _mode,
        serviceDate: _mode == MaintenanceMode.completed
            ? formData[MaintenanceFormFields.date] as DateTime? ?? DateTime.now()
            : null,
        odometerAtService: _mode == MaintenanceMode.completed ? odometerAtService : null,
        workshop: formData[MaintenanceFormFields.workshop] as String?,
        notes: formData[MaintenanceFormFields.notes] as String?,
        nextDate: formData[MaintenanceFormFields.nextMaintenanceDate] as DateTime?,
        nextOdometer: nextOdometer,
        cost: formData[MaintenanceFormFields.cost] != null &&
                (formData[MaintenanceFormFields.cost] as String).isNotEmpty
            ? double.tryParse(formData[MaintenanceFormFields.cost] as String)
            : null,
      );
    }
    return null;
  }

  /// Extracts the relative km interval from the form for the API.
  int? buildNextKmInterval() {
    if (formKey.currentState == null) return null;
    final formData = formKey.currentState!.value;
    final raw = formData[MaintenanceFormFields.nextMaintenanceMileage];
    if (raw == null) return null;
    final str = raw as String;
    if (str.isEmpty) return null;
    return int.tryParse(str);
  }

  bool shouldChangeVehicleMileage(int currentMileage, int newMileage) =>
      newMileage > currentMileage;
}
