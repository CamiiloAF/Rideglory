import 'package:dartz/dartz.dart';

import '../../../core/exceptions/domain_exception.dart';
import 'maintenance.dart';
import 'register_maintenance_params.dart';
import 'vehicle_option.dart';

/// Puerto hacia los datos de mantenimiento y las motos del rider (lectura
/// mínima de `vehicles`, sin depender de la feature `garage`).
abstract class MaintenanceRepository {
  Future<Either<DomainException, List<VehicleOption>>> getVehicles();

  Future<Either<DomainException, List<Maintenance>>> getMaintenances();

  /// Inserta el mantenimiento y, si el kilometraje reportado supera el
  /// odómetro actual de la moto, lo actualiza en la misma operación (D5):
  /// vía la función de Postgres `register_maintenance`.
  Future<Either<DomainException, Maintenance>> registerMaintenance(
    RegisterMaintenanceParams params,
  );

  Future<Either<DomainException, Maintenance>> updateMaintenance(
    String id,
    RegisterMaintenanceParams params,
  );

  Future<Either<DomainException, Unit>> deleteMaintenance(String id);
}
