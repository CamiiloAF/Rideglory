import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/vehicles/data/service/vehicle_service.dart';
import 'package:rideglory/features/vehicles/domain/models/soat_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
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
        return vehicles.map((vehicle) => vehicle.toModel()).toList();
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
  Future<Either<DomainException, void>> deleteVehicle(String id) async {
    return executeService(
      function: () async {
        await _vehicleService.deleteVehicle(id);
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
  Future<Either<DomainException, SoatModel>> upsertSoat({
    required String vehicleId,
    required SoatModel soat,
  }) {
    return executeService(
      function: () async {
        final dto = await _vehicleService.upsertSoat(vehicleId, {
          'policyNumber': soat.policyNumber,
          'startDate': soat.startDate.toIso8601String(),
          'expiryDate': soat.expiryDate.toIso8601String(),
          'insurer': soat.insurer,
          if (soat.documentUrl != null) 'documentUrl': soat.documentUrl,
        });
        return dto.toModel();
      },
    );
  }

  @override
  Future<Either<DomainException, SoatModel>> getSoat(String vehicleId) {
    return executeService(
      function: () async {
        final dto = await _vehicleService.getSoat(vehicleId);
        return dto.toModel();
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
    }..removeWhere((_, value) => value == null);
  }
}
