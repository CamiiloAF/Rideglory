import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../model/maintenance_model.dart';
import '../model/maintenance_user_list_aggregate.dart';
import '../repository/maintenance_repository.dart';

@injectable
class GetMaintenanceListUseCase {
  GetMaintenanceListUseCase(this.maintenanceRepository);

  final MaintenanceRepository maintenanceRepository;

  Future<Either<DomainException, MaintenanceUserListAggregate>> execute({
    List<MaintenanceType>? types,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await maintenanceRepository.getMaintenancesByUserId(
      types: types,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
