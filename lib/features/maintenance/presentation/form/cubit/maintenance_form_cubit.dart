import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/add_maintenance_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_form_fields.dart';

import '../../../domain/use_cases/update_maintenance_use_case.dart';

@injectable
class MaintenanceFormCubit extends Cubit<ResultState<MaintenanceModel>> {
  MaintenanceFormCubit(
    this._addMaintenanceUseCase,
    this._updateMaintenanceUseCase,
  ) : super(const ResultState.initial());

  final formKey = GlobalKey<FormBuilderState>();

  final AddMaintenanceUseCase _addMaintenanceUseCase;
  final UpdateMaintenanceUseCase _updateMaintenanceUseCase;

  MaintenanceModel? _editingMaintenance;
  VehicleModel? preselectedVehicle;
  String? userId;
  String? _resolvedVehicleId;
  int? _currentVehicleMileage;
  MaintenanceType? _selectedType;

  bool get isEditing => _editingMaintenance != null;
  MaintenanceModel? get editingMaintenance => _editingMaintenance;
  int? get currentVehicleMileage => _currentVehicleMileage;

  void initialize({
    MaintenanceModel? maintenance,
    VehicleModel? preselectedVehicle,
  }) {
    this.preselectedVehicle = preselectedVehicle;
    _editingMaintenance = maintenance;
    _selectedType = maintenance?.type;
    userId = maintenance?.userId;
    _resolvedVehicleId = preselectedVehicle?.id ?? maintenance?.vehicleId;
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

  Future<void> createFollowUpScheduled(MaintenanceModel followUp) async {
    await _addMaintenanceUseCase(followUp);
  }

  Future<void> saveMaintenance(MaintenanceModel maintenanceToSave) async {
    emit(const ResultState.loading());

    final result = maintenanceToSave.id != null
        ? await _updateMaintenanceUseCase(maintenanceToSave)
        : await _addMaintenanceUseCase(maintenanceToSave);

    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (maintenance) => emit(ResultState.data(data: maintenance)),
    );
  }

  MaintenanceModel? buildMaintenanceToSave({bool isScheduled = false}) {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      final formData = formKey.currentState!.value;

      final type =
          (_selectedType ??
          formData[MaintenanceFormFields.type] as MaintenanceType?)!;
      final maintenanceToSave = MaintenanceModel(
        id: _editingMaintenance?.id,
        vehicleId: _resolvedVehicleId,
        userId: userId,
        type: type,
        notes: formData[MaintenanceFormFields.notes] as String?,
        date:
            (formData[MaintenanceFormFields.date] as DateTime?) ??
            DateTime.now(),
        nextMaintenanceDate:
            formData[MaintenanceFormFields.nextMaintenanceDate] as DateTime?,
        maintanceMileage:
            formData[MaintenanceFormFields.currentMileage] != null &&
                (formData[MaintenanceFormFields.currentMileage] as String)
                    .isNotEmpty
            ? int.parse(
                formData[MaintenanceFormFields.currentMileage] as String,
              )
            : (_currentVehicleMileage ?? 0),
        isScheduled: isScheduled,
        nextMaintenanceMileage:
            formData[MaintenanceFormFields.nextMaintenanceMileage] != null &&
                (formData[MaintenanceFormFields.nextMaintenanceMileage]
                        as String)
                    .isNotEmpty
            ? int.parse(
                formData[MaintenanceFormFields.nextMaintenanceMileage]
                    as String,
              )
            : null,
        cost:
            formData[MaintenanceFormFields.cost] != null &&
                (formData[MaintenanceFormFields.cost] as String).isNotEmpty
            ? double.parse(formData[MaintenanceFormFields.cost] as String)
            : null,
      );
      return maintenanceToSave;
    } else {
      return null;
    }
  }

  bool shouldChangeVehicleMileage(int currentMileage, int newMileage) =>
      newMileage > currentMileage;
}
