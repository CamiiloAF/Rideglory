import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../model/maintenance_model.dart';
import '../repository/maintenance_repository.dart';

@injectable
class GetMaintenanceListUseCase {
  GetMaintenanceListUseCase(this.maintenanceRepository);

  final MaintenanceRepository maintenanceRepository;

  Future<Either<DomainException, List<MaintenanceModel>>> execute(
    String userId,
  ) async {
    return await maintenanceRepository.getMaintenancesByUserId(userId);
  }
}
