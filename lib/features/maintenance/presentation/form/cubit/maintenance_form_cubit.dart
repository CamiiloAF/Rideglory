import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/add_maintenance_use_case.dart';

import '../../../domain/use_cases/update_maintenance_use_case.dart';

part 'maintenance_form_cubit.freezed.dart';
part 'maintenance_form_state.dart';

@injectable
class MaintenanceFormCubit extends Cubit<MaintenanceFormState> {
  MaintenanceFormCubit(
    this._addMaintenanceUseCase,
    this._updateMaintenanceUseCase,
  ) : super(const MaintenanceFormState.initial());

  final formKey = GlobalKey<FormBuilderState>();

  final AddMaintenanceUseCase _addMaintenanceUseCase;
  final UpdateMaintenanceUseCase _updateMaintenanceUseCase;

  void initialize({MaintenanceModel? maintenance}) {
    if (maintenance != null) {
      emit(MaintenanceFormState.editing(maintenance: maintenance));
    } else {
      emit(const MaintenanceFormState.initial());
    }
  }

  Future<void> saveMaintenance(MaintenanceModel maintenanceToSave) async {
      emit(const MaintenanceFormState.loading());

      final result = await state.maybeWhen(
        editing: (_) async =>
            await _updateMaintenanceUseCase(maintenanceToSave),
        orElse: () async => await _addMaintenanceUseCase(maintenanceToSave),
      );

      result.fold(
        (error) => emit(MaintenanceFormState.error(message: error.message)),
        (maintenance) =>
            emit(MaintenanceFormState.success(maintenance: maintenance)),
      );
    
  }

  MaintenanceModel? buildMaintenanceToSave() {
    if (formKey.currentState?.saveAndValidate() ?? false) {

    final formData = formKey.currentState!.value;

    final maintenanceToSave = MaintenanceModel(
      id: state.maybeWhen(
        editing: (maintenance) => maintenance.id,
        orElse: () => null,
      ),
      name: formData['name'] as String,
      type: formData['type'] as MaintenanceType,
      notes: formData['notes'] as String?,
      date: formData['date'] as DateTime,
      nextMaintenanceDate: formData['nextMaintenanceDate'] as DateTime?,
      maintanceMileage: double.parse(formData['currentMileage'] as String),
      distanceUnit: formData['distanceUnit'] as DistanceUnit,
      receiveAlert: formData['receiveAlert'] as bool? ?? false,
      nextMaintenanceMileage:
          formData['nextMaintenanceMileage'] != null &&
              (formData['nextMaintenanceMileage'] as String).isNotEmpty
          ? double.parse(formData['nextMaintenanceMileage'] as String)
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
