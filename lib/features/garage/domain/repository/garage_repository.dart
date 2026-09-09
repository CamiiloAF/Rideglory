import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../models/vehicle.dart';

/// Datos nuevos o de reemplazo de una moto. Los campos nulos en actualización
/// no se tocan; el año, cilindraje y placa sí pueden quedar en `null`
/// explícitamente porque son opcionales.
class VehicleInput {
  const VehicleInput({
    required this.brand,
    required this.model,
    required this.currentMileage,
    this.year,
    this.engineCc,
    this.licensePlate,
    this.imageBytes,
    this.imageExtension,
  });

  final String brand;
  final String model;
  final int currentMileage;
  final int? year;
  final int? engineCc;
  final String? licensePlate;

  /// Bytes de la foto a subir, si el rider eligió una. `null` conserva la
  /// foto existente en una actualización, o deja la moto sin foto al crear.
  final Uint8List? imageBytes;
  final String? imageExtension;
}

abstract class GarageRepository {
  Future<Either<DomainException, List<Vehicle>>> getVehicles();

  Future<Either<DomainException, Vehicle>> createVehicle(VehicleInput input);

  Future<Either<DomainException, Vehicle>> updateVehicle(
    String vehicleId,
    VehicleInput input,
  );

  Future<Either<DomainException, Unit>> archiveVehicle(String vehicleId);

  Future<Either<DomainException, Unit>> unarchiveVehicle(String vehicleId);

  Future<Either<DomainException, Unit>> setMainVehicle(String vehicleId);

  Future<Either<DomainException, Unit>> deleteVehicle(String vehicleId);
}
