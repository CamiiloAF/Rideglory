import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../model/maintenance_model.dart';
import '../repository/maintenance_repository.dart';

@injectable
class AddMaintenanceUseCase {
  AddMaintenanceUseCase(this.maintenanceRepository);

  final MaintenanceRepository maintenanceRepository;

  Future<Either<DomainException, MaintenanceModel>> call(
    MaintenanceModel maintenance,
  ) async {
    return await maintenanceRepository.addMaintenance(maintenance);
  }
}
