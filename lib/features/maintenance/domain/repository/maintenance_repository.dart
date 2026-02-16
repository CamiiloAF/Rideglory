import 'package:dartz/dartz.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

import '../../../../core/exceptions/domain_exception.dart';

abstract class MaintenanceRepository {
  Future<Either<DomainException, List<MaintenanceModel>>>
  getMaintenancesByUserId();

  Future<Either<DomainException, MaintenanceModel>> addMaintenance(
    MaintenanceModel maintenance,
  );

  Future<Either<DomainException, MaintenanceModel>> updateMaintenance(
    MaintenanceModel maintenance,
  );

  Future<Either<DomainException, Nothing>> deleteMaintenance(
    String id,
  );
}
