import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_document_alert.dart';
import '../../domain/repository/garage_repository.dart';
import '../datasources/garage_remote_datasource.dart';
import '../dto/vehicle_dto.dart';

@Injectable(as: GarageRepository)
class GarageRepositoryImpl implements GarageRepository {
  GarageRepositoryImpl(this._datasource);

  final GarageRemoteDatasource _datasource;

  @override
  Future<Either<DomainException, List<Vehicle>>> getVehicles() async {
    try {
      final dtos = await _datasource.fetchVehicles();
      final expiries = await _datasource.fetchDocumentExpiries(dtos.map((dto) => dto.id).toList());
      final alertsByVehicleId = _groupAlertsByVehicle(expiries);
      final vehicles = await Future.wait(
        dtos.map((dto) => _toDomainWithImage(dto, alertsByVehicleId[dto.id])),
      );
      return Right(vehicles);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<DomainException, Vehicle>> createVehicle(VehicleInput input) async {
    try {
      var dto = await _datasource.insertVehicle(_toValues(input));
      dto = await _withUploadedImage(dto, input);
      return Right(await _toDomainWithImage(dto, null));
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<DomainException, Vehicle>> updateVehicle(
    String vehicleId,
    VehicleInput input,
  ) async {
    try {
      var dto = await _datasource.updateVehicle(vehicleId, _toValues(input));
      dto = await _withUploadedImage(dto, input);
      return Right(await _toDomainWithImage(dto, null));
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<DomainException, Unit>> archiveVehicle(String vehicleId) async {
    try {
      await _datasource.archiveVehicle(vehicleId);
      return const Right(unit);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<DomainException, Unit>> unarchiveVehicle(String vehicleId) async {
    try {
      await _datasource.unarchiveVehicle(vehicleId);
      return const Right(unit);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<DomainException, Unit>> setMainVehicle(String vehicleId) async {
    try {
      await _datasource.setMainVehicle(vehicleId);
      return const Right(unit);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<DomainException, Unit>> deleteVehicle(String vehicleId) async {
    try {
      await _datasource.deleteVehicle(vehicleId);
      return const Right(unit);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  Map<String, dynamic> _toValues(VehicleInput input) {
    return {
      'name': '${input.brand} ${input.model}'.trim(),
      'brand': input.brand,
      'model': input.model,
      'year': input.year,
      'engine_cc': input.engineCc,
      'license_plate': input.licensePlate,
      'current_mileage': input.currentMileage,
    };
  }

  Future<VehicleDto> _withUploadedImage(VehicleDto dto, VehicleInput input) async {
    if (input.imageBytes == null || input.imageExtension == null) return dto;
    final imagePath = await _datasource.uploadImage(
      vehicleId: dto.id,
      bytes: input.imageBytes!,
      extension: input.imageExtension!,
    );
    return _datasource.updateVehicle(dto.id, {'image_path': imagePath});
  }

  Future<Vehicle> _toDomainWithImage(VehicleDto dto, VehicleDocumentAlert? alert) async {
    if (dto.imagePath == null) return dto.toDomain(documentAlert: alert);
    try {
      final signedUrl = await _datasource.createSignedImageUrl(dto.imagePath!);
      return dto.toDomain(imageUrl: signedUrl, documentAlert: alert);
    } catch (_) {
      return dto.toDomain(documentAlert: alert);
    }
  }

  Map<String, VehicleDocumentAlert> _groupAlertsByVehicle(List<Map<String, dynamic>> rows) {
    final byVehicle = <String, List<({DocumentAlertKind kind, DateTime expiryDate})>>{};
    for (final row in rows) {
      final vehicleId = row['vehicle_id'] as String;
      final kind = row['kind'] == 'soat' ? DocumentAlertKind.soat : DocumentAlertKind.rtm;
      final expiryDate = DateTime.parse(row['expiry_date'] as String);
      byVehicle.putIfAbsent(vehicleId, () => []).add((kind: kind, expiryDate: expiryDate));
    }
    final now = DateTime.now();
    final alerts = <String, VehicleDocumentAlert>{};
    for (final entry in byVehicle.entries) {
      final alert = VehicleDocumentAlert.mostUrgent(entry.value, now);
      if (alert != null) alerts[entry.key] = alert;
    }
    return alerts;
  }

  DomainException _mapError(Object error) {
    return DomainException(message: error.toString());
  }
}
