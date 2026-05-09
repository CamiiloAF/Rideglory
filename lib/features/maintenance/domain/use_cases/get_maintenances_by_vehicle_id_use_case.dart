import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../model/maintenance_vehicle_list_result.dart';
import '../repository/maintenance_repository.dart';

@injectable
class GetMaintenancesByVehicleIdUseCase {
  GetMaintenancesByVehicleIdUseCase(this.maintenanceRepository);

  final MaintenanceRepository maintenanceRepository;

  Future<Either<DomainException, MaintenanceVehicleListResult>> execute(
    String vehicleId,
  ) async {
    return await maintenanceRepository.getMaintenancesByVehicleId(vehicleId);
  }
}
