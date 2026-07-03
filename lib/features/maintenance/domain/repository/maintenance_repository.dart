import 'package:dartz/dartz.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_user_list_aggregate.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_vehicle_list_result.dart';

import '../../../../core/exceptions/domain_exception.dart';

abstract class MaintenanceRepository {
  Future<Either<DomainException, MaintenanceUserListAggregate>>
  getMaintenancesByUserId({
    List<MaintenanceType>? types,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<DomainException, MaintenanceVehicleListResult>>
  getMaintenancesByVehicleId(
    String vehicleId, {
    List<MaintenanceType>? types,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Returns a list of 1 or 2 models:
  /// - 1 model when mode == scheduled or no next fields provided
  /// - 2 models when mode == completed AND next fields provided (auto-created scheduled record)
  Future<Either<DomainException, List<MaintenanceModel>>> addMaintenance(
    MaintenanceModel maintenance,
    int? nextKmInterval,
  );

  Future<Either<DomainException, MaintenanceModel>> updateMaintenance(
    MaintenanceModel maintenance,
  );

  Future<Either<DomainException, Nothing>> deleteMaintenance(
    MaintenanceModel maintenance,
  );
}
