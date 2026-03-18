import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../model/maintenance_model.dart';
import '../repository/maintenance_repository.dart';

@injectable
class GetMaintenancesByVehicleIdUseCase {
  GetMaintenancesByVehicleIdUseCase(this.maintenanceRepository);

  final MaintenanceRepository maintenanceRepository;

  Future<Either<DomainException, List<MaintenanceModel>>> execute(
    String vehicleId,
  ) async {
    return await maintenanceRepository.getMaintenancesByVehicleId(vehicleId);
  }
}
