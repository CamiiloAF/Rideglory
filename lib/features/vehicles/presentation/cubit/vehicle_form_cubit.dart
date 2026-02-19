import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/add_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/update_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';

part 'vehicle_form_state.dart';
part 'vehicle_form_cubit.freezed.dart';

@injectable
class VehicleFormCubit extends Cubit<VehicleFormState> {
  final AddVehicleUseCase _addVehicleUseCase;
  final UpdateVehicleUseCase _updateVehicleUseCase;

  final formKey = GlobalKey<FormBuilderState>();

  VehicleFormCubit(this._addVehicleUseCase, this._updateVehicleUseCase)
    : super(VehicleFormState());

  void initialize({VehicleModel? vehicle}) {
    if (vehicle != null) {
      emit(state.copyWith(vehicle: vehicle));
    }
  }

  Future<void> saveVehicle(VehicleModel vehicle) async {
    emit(state.copyWith(vehicleResult: const ResultState.loading()));

    final result = state.isEditing
        ? await _updateVehicleUseCase(vehicle)
        : await _addVehicleUseCase(vehicle);

    result.fold(
      (error) =>
          emit(state.copyWith(vehicleResult: ResultState.error(error: error))),
      (savedVehicle) => emit(
        state.copyWith(vehicleResult: ResultState.data(data: savedVehicle)),
      ),
    );
  }

  Future<void> addMultipleVehicles(List<VehicleModel> vehicles) async {
    emit(state.copyWith(vehicleResult: const ResultState.loading()));

    bool isSuccess = false;
    VehicleModel? firstVehicleSaved;

    for (var vehicle in vehicles) {
      final result = await _addVehicleUseCase(vehicle);
      final hasError = result.fold((error) {
        emit(state.copyWith(vehicleResult: ResultState.error(error: error)));
        return true;
      }, (_) => false);

      if (hasError) return;

      firstVehicleSaved ??= vehicle;
      isSuccess = true;
    }

    if (isSuccess) {
      emit(
        state.copyWith(
          vehicleResult: ResultState.data(data: firstVehicleSaved!),
        ),
      );
    }
  }

  VehicleModel? buildVehicleToSave() {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      final formData = formKey.currentState!.value;

      // If editing an archived vehicle, unarchive it
      final wasArchived =
          state.isEditing && (state.vehicle?.isArchived ?? false);

      final vehicleToSave = VehicleModel(
        id: state.isEditing ? state.vehicle!.id : null,
        name: formData[VehicleFormFields.name] as String,
        brand: (formData[VehicleFormFields.brand] as String?)?.isEmpty ?? true
            ? null
            : formData[VehicleFormFields.brand] as String?,
        model: (formData[VehicleFormFields.model] as String?)?.isEmpty ?? true
            ? null
            : formData[VehicleFormFields.model] as String?,
        year:
            formData[VehicleFormFields.year] != null &&
                (formData[VehicleFormFields.year] as String).isNotEmpty
            ? int.tryParse(formData[VehicleFormFields.year] as String)
            : null,
        currentMileage:
            formData[VehicleFormFields.currentMileage] != null &&
                (formData[VehicleFormFields.currentMileage] as String)
                    .isNotEmpty
            ? int.tryParse(
                    formData[VehicleFormFields.currentMileage] as String,
                  ) ??
                  0
            : 0,
        distanceUnit: formData[VehicleFormFields.distanceUnit] as DistanceUnit,
        vehicleType:
            formData[VehicleFormFields.vehicleType] as VehicleType? ??
            VehicleType.motorcycle,
        licensePlate:
            (formData[VehicleFormFields.licensePlate] as String?)?.isEmpty ??
                true
            ? null
            : formData[VehicleFormFields.licensePlate] as String?,
        vin: (formData[VehicleFormFields.vin] as String?)?.isEmpty ?? true
            ? null
            : formData[VehicleFormFields.vin] as String?,
        purchaseDate: formData[VehicleFormFields.purchaseDate] as DateTime?,
        isArchived: wasArchived ? false : (state.vehicle?.isArchived ?? false),
      );
      return vehicleToSave;
    } else {
      return null;
    }
  }

  void reset() {
    emit(
      state.copyWith(vehicleResult: const ResultState.initial(), vehicle: null),
    );
  }
}
