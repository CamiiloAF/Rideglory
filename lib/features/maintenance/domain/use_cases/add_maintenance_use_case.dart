import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../model/maintenance_model.dart';
import '../repository/maintenance_repository.dart';

@injectable
class AddMaintenanceUseCase {
  AddMaintenanceUseCase(this.maintenanceRepository);

  final MaintenanceRepository maintenanceRepository;

  /// Returns a list of 1 or 2 [MaintenanceModel]:
  /// - 1 record for scheduled mode or completed without next fields
  /// - 2 records for completed mode with nextKmInterval and/or nextDate
  Future<Either<DomainException, List<MaintenanceModel>>> call(
    MaintenanceModel maintenance, {
    int? nextKmInterval,
  }) async {
    return await maintenanceRepository.addMaintenance(maintenance, nextKmInterval);
  }
}
