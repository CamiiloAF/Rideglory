import 'package:dartz/dartz.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_user_list_aggregate.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_vehicle_list_result.dart';

import '../../../../core/exceptions/domain_exception.dart';

abstract class MaintenanceRepository {
  Future<Either<DomainException, MaintenanceUserListAggregate>>
      getMaintenancesByUserId();

  Future<Either<DomainException, MaintenanceVehicleListResult>>
      getMaintenancesByVehicleId(String vehicleId);

  Future<Either<DomainException, MaintenanceModel>> addMaintenance(
    MaintenanceModel maintenance,
  );

  Future<Either<DomainException, MaintenanceModel>> updateMaintenance(
    MaintenanceModel maintenance,
  );

  Future<Either<DomainException, Nothing>> deleteMaintenance(
    MaintenanceModel maintenance,
  );
}
