import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../repository/maintenance_repository.dart';

@injectable
class DeleteMaintenanceUseCase {
  DeleteMaintenanceUseCase(this.maintenanceRepository);

  final MaintenanceRepository maintenanceRepository;

  Future<Either<DomainException, Nothing>> execute(String id) async {
    return await maintenanceRepository.deleteMaintenance(id);
  }
}
