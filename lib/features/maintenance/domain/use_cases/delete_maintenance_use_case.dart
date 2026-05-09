import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../model/maintenance_model.dart';
import '../repository/maintenance_repository.dart';

@injectable
class DeleteMaintenanceUseCase {
  DeleteMaintenanceUseCase(this.maintenanceRepository);

  final MaintenanceRepository maintenanceRepository;

  Future<Either<DomainException, Nothing>> call(
    MaintenanceModel maintenance,
  ) async {
    return maintenanceRepository.deleteMaintenance(maintenance);
  }
}
