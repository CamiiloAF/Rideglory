import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/vehicles/data/dto/soat_dto.dart';
import 'package:rideglory/features/vehicles/data/service/vehicle_service.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_soat_form_data.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

@Injectable(as: VehicleRepository)
class VehicleRepositoryImpl implements VehicleRepository {
  VehicleRepositoryImpl(this._vehicleService, this._storage);

  final VehicleService _vehicleService;
  final FirebaseStorage _storage;

  @override
  Future<Either<DomainException, List<VehicleModel>>> getMyVehicles() async {
    return executeService(
      function: () async {
        final vehicles = await _vehicleService.getMyVehicles();
        return List<VehicleModel>.from(vehicles);
      },
    );
  }

  @override
  Future<Either<DomainException, VehicleModel>> setMainVehicle(
    String vehicleId,
  ) async {
    return executeService(
      function: () async {
        return await _vehicleService.setMyMainVehicle(vehicleId);
      },
    );
  }

  @override
  Future<Either<DomainException, VehicleModel>> addVehicle(
    VehicleModel vehicle,
  ) async {
    return executeService(
      function: () async {
        return _vehicleService.createMyVehicle(_vehicleRequest(vehicle));
      },
    );
  }

  @override
  Future<Either<DomainException, VehicleModel>> updateVehicle(
    VehicleModel vehicle,
  ) async {
    if (vehicle.id == null) {
      throw const DomainException(
        message: 'Vehicle ID is required for update.',
      );
    }

    final updatedVehicle = vehicle.copyWith(updatedDate: DateTime.now());

    return executeService(
      function: () async {
        return _vehicleService.updateVehicle(
          updatedVehicle.id!,
          _vehicleRequest(updatedVehicle),
        );
      },
    );
  }

  @override
  Future<Either<DomainException, void>> permanentlyDeleteVehicle(
    String id,
  ) async {
    return executeService(
      function: () async {
        await _vehicleService.permanentlyDeleteVehicle(id);
      },
    );
  }

  @override
  Future<Either<DomainException, String>> uploadVehicleImage({
    required String vehicleId,
    required String localImagePath,
  }) {
    return executeService(
      function: () async {
        final file = File(localImagePath);
        final ref = _storage.ref().child('vehicles/$vehicleId/cover.jpg');
        final uploadTask = await ref.putFile(file);
        return uploadTask.ref.getDownloadURL();
      },
    );
  }

  @override
  Future<Either<DomainException, VehicleSoatFormData>> upsertSoat({
    required String vehicleId,
    required VehicleSoatFormData soat,
  }) {
    return executeService(
      function: () async {
        final dto = await _vehicleService.upsertSoat(
          vehicleId,
          soat.toJson(),
        );
        return dto.toFormData();
      },
    );
  }

  @override
  Future<Either<DomainException, VehicleSoatFormData>> getSoat(
    String vehicleId,
  ) {
    return executeService(
      function: () async {
        final dto = await _vehicleService.getSoat(vehicleId);
        return dto.toFormData();
      },
    );
  }

  Map<String, dynamic> _vehicleRequest(VehicleModel vehicle) {
    return {
      'name': vehicle.name,
      'brand': vehicle.brand,
      'model': vehicle.model,
      'year': vehicle.year,
      'currentMileage': vehicle.currentMileage,
      'licensePlate': vehicle.licensePlate,
      'vin': vehicle.vin,
      'purchaseDate': vehicle.purchaseDate?.toApiIso8601String(),
      'imageUrl': vehicle.imageUrl,
      'isArchived': vehicle.isArchived,
      'engine': vehicle.engine,
      'horsepower': vehicle.horsepower,
      'torque': vehicle.torque,
      'weight': vehicle.weight,
    }..removeWhere((_, value) => value == null);
  }
}
