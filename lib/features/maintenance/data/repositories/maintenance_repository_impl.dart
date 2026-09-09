import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/exceptions/domain_exception.dart';
import '../../domain/maintenance.dart';
import '../../domain/maintenance_repository.dart';
import '../../domain/register_maintenance_params.dart';
import '../../domain/vehicle_option.dart';
import '../datasources/maintenance_datasource.dart';

/// El `message` de [DomainException] nunca es texto para mostrar al rider
/// (eso vive en el `.arb` y lo elige la presentación): aquí solo queda un
/// identificador corto útil para logs/Sentry.
@Injectable(as: MaintenanceRepository)
class MaintenanceRepositoryImpl implements MaintenanceRepository {
  const MaintenanceRepositoryImpl(this._datasource);

  final MaintenanceDatasource _datasource;

  @override
  Future<Either<DomainException, List<VehicleOption>>> getVehicles() async {
    return _guard(() async {
      final dtos = await _datasource.getVehicles();
      return dtos.map((dto) => dto.toDomain()).toList();
    });
  }

  @override
  Future<Either<DomainException, List<Maintenance>>> getMaintenances() async {
    return _guard(() async {
      final dtos = await _datasource.getMaintenances();
      return dtos.map((dto) => dto.toDomain()).toList();
    });
  }

  @override
  Future<Either<DomainException, Maintenance>> registerMaintenance(
    RegisterMaintenanceParams params,
  ) async {
    return _guard(() async {
      final reminder = params.reminder;
      final dto = await _datasource.registerMaintenance(
        vehicleId: params.vehicleId,
        type: params.type,
        serviceDate: params.serviceDate,
        odometer: params.odometer,
        cost: params.cost,
        workshop: params.workshop,
        notes: params.notes,
        nextDate: reminder?.everyMonths != null
            ? DateTime(
                params.serviceDate.year,
                params.serviceDate.month + reminder!.everyMonths!,
                params.serviceDate.day,
              )
            : null,
        nextOdometer: reminder?.everyKm != null
            ? params.odometer + reminder!.everyKm!
            : null,
      );
      return dto.toDomain();
    });
  }

  @override
  Future<Either<DomainException, Maintenance>> updateMaintenance(
    String id,
    RegisterMaintenanceParams params,
  ) async {
    return _guard(() async {
      final reminder = params.reminder;
      final dto = await _datasource.updateMaintenance(
        id: id,
        vehicleId: params.vehicleId,
        type: params.type,
        serviceDate: params.serviceDate,
        odometer: params.odometer,
        cost: params.cost,
        workshop: params.workshop,
        notes: params.notes,
        nextDate: reminder?.everyMonths != null
            ? DateTime(
                params.serviceDate.year,
                params.serviceDate.month + reminder!.everyMonths!,
                params.serviceDate.day,
              )
            : null,
        nextOdometer: reminder?.everyKm != null
            ? params.odometer + reminder!.everyKm!
            : null,
      );
      return dto.toDomain();
    });
  }

  @override
  Future<Either<DomainException, Unit>> deleteMaintenance(String id) async {
    return _guard(() async {
      await _datasource.deleteMaintenance(id);
      return unit;
    });
  }

  Future<Either<DomainException, T>> _guard<T>(
    Future<T> Function() action,
  ) async {
    try {
      return Right(await action());
    } on PostgrestException catch (error) {
      return Left(DomainException(message: 'postgrest_error: ${error.code}'));
    } catch (error) {
      return Left(DomainException(message: 'unknown_error: $error'));
    }
  }
}
