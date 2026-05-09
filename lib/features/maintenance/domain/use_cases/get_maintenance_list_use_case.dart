import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../model/maintenance_user_list_aggregate.dart';
import '../repository/maintenance_repository.dart';

@injectable
class GetMaintenanceListUseCase {
  GetMaintenanceListUseCase(this.maintenanceRepository);

  final MaintenanceRepository maintenanceRepository;

  Future<Either<DomainException, MaintenanceUserListAggregate>> execute() async {
    return await maintenanceRepository.getMaintenancesByUserId();
  }
}
