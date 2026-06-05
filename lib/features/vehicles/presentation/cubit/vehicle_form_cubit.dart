import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/image_storage_service.dart';
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
  final ImageStorageService _imageStorageService;
  final AnalyticsService _analytics;

  VehicleFormCubit(
    this._addVehicleUseCase,
    this._updateVehicleUseCase,
    this._imageStorageService,
    this._analytics,
  ) : super(VehicleFormState());

  final formKey = GlobalKey<FormBuilderState>();

  void initialize({VehicleModel? vehicle}) {
    if (vehicle != null) {
      emit(state.copyWith(vehicle: vehicle));
    }
  }

  Future<void> pickSoatDocument() async {
    final file = await _imageStorageService.pickImageFromGallery();
    if (file != null) {
      emit(state.copyWith(soatLocalPath: file.path));
    }
  }

  void setSoatFromLocalPath(String path) {
    emit(state.copyWith(soatLocalPath: path));
  }

  void clearSoatDocument() {
    emit(state.copyWith(soatLocalPath: null));
  }

  void storePendingManualSoat(PendingManualSoat data) {
    emit(state.copyWith(pendingManualSoat: data));
  }

  void clearPendingManualSoat() {
    emit(state.copyWith(pendingManualSoat: null));
  }

  void storePendingRtm(PendingRtm data) {
    emit(state.copyWith(pendingRtm: data));
  }

  void clearPendingRtm() {
    emit(state.copyWith(pendingRtm: null));
  }

  Future<void> pickTechReviewDocument() async {
    final file = await _imageStorageService.pickImageFromGallery();
    if (file != null) {
      emit(state.copyWith(techReviewLocalPath: file.path));
    }
  }

  void clearTechReviewDocument() {
    emit(state.copyWith(techReviewLocalPath: null));
  }

  Future<void> saveVehicle(
    VehicleModel vehicle, {
    String? localImagePath,
  }) async {
    emit(state.copyWith(vehicleResult: const ResultState.loading()));

    final result = state.isEditing
        ? await _saveExistingVehicle(
            vehicle,
            localImagePath: localImagePath,
          )
        : await _createNewVehicle(
            vehicle,
            localImagePath: localImagePath,
          );

    result.fold(
      (error) => emit(state.copyWith(vehicleResult: ResultState.error(error: error))),
      (savedVehicle) {
        final eventName = state.isEditing
            ? AnalyticsEvents.vehicleUpdated
            : AnalyticsEvents.vehicleAdded;
        _analytics
            .logEvent(eventName, {
              AnalyticsParams.hadPhoto: savedVehicle.imageUrl != null ? 1 : 0,
            })
            .ignore();
        emit(
          state.copyWith(vehicleResult: ResultState.data(data: savedVehicle)),
        );
      },
    );
  }

  Future<Either<DomainException, VehicleModel>> _saveExistingVehicle(
    VehicleModel vehicle, {
    String? localImagePath,
  }) async {
    final vehicleWithImageResult = await _buildVehicleWithImage(
      vehicle,
      localImagePath: localImagePath,
    );

    return vehicleWithImageResult.fold(Left.new, _updateVehicleUseCase.call);
  }

  Future<Either<DomainException, VehicleModel>> _createNewVehicle(
    VehicleModel vehicle, {
    String? localImagePath,
  }) async {
    final vehicleWithImageResult = await _buildVehicleWithImage(
      vehicle,
      localImagePath: localImagePath,
    );

    return vehicleWithImageResult.fold(Left.new, _addVehicleUseCase.call);
  }

  Future<Either<DomainException, VehicleModel>> _buildVehicleWithImage(
    VehicleModel vehicle, {
    String? localImagePath,
  }) async {
    try {
      // Keep existing remote image while editing when no new local image is selected.
      var imageUrl = state.isEditing ? state.vehicle?.imageUrl : vehicle.imageUrl;

      if (localImagePath != null) {
        final imageName =
            vehicle.id ?? 'new_${DateTime.now().millisecondsSinceEpoch}';
        imageUrl = await _imageStorageService.uploadImage(
          image: XFile(localImagePath),
          storagePath: 'vehicles/$imageName.jpg',
        );
      }

      return Right(vehicle.copyWith(imageUrl: imageUrl));
    } catch (error) {
      if (error is DomainException) {
        return Left(error);
      }
      return Left(DomainException(message: error.toString()));
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
        brand: formData[VehicleFormFields.brand] as String,
        model: formData[VehicleFormFields.model] as String,
        year: int.tryParse(formData[VehicleFormFields.year] as String),
        currentMileage:
            int.tryParse(
              formData[VehicleFormFields.currentMileage] as String,
            ) ??
            0,
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
        isMainVehicle: state.vehicle?.isMainVehicle ?? false,
        color: (formData[VehicleFormFields.color] as String?)?.isEmpty ?? true
            ? null
            : formData[VehicleFormFields.color] as String?,
        engine: (formData[VehicleFormFields.engine] as String?)?.isEmpty ?? true
            ? null
            : formData[VehicleFormFields.engine] as String?,
        horsepower:
            (formData[VehicleFormFields.horsepower] as String?)?.isEmpty ?? true
            ? null
            : formData[VehicleFormFields.horsepower] as String?,
        torque: (formData[VehicleFormFields.torque] as String?)?.isEmpty ?? true
            ? null
            : formData[VehicleFormFields.torque] as String?,
        weight: (formData[VehicleFormFields.weight] as String?)?.isEmpty ?? true
            ? null
            : formData[VehicleFormFields.weight] as String?,
      );
      return vehicleToSave;
    } else {
      return null;
    }
  }

  void reset() {
    emit(
      state.copyWith(
        vehicleResult: const ResultState.initial(),
        vehicle: null,
        localImagePath: null,
      ),
    );
  }
}
