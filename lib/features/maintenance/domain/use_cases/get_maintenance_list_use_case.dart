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

  /// Si [vehicleId] viene, solo se consulta ese vehículo (un único GET).
  /// Si no, se agregan todos los vehículos del usuario (un GET por vehículo).
  Future<Either<DomainException, MaintenanceUserListAggregate>> execute({
    String? vehicleId,
    List<MaintenanceType>? types,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (vehicleId != null) {
      final result = await maintenanceRepository.getMaintenancesByVehicleId(
        vehicleId,
        types: types,
        startDate: startDate,
        endDate: endDate,
      );
      return result.map(
        (page) => MaintenanceUserListAggregate(
          items: page.items,
          summariesByVehicleId: {vehicleId: page.summary},
        ),
      );
    }
    return await maintenanceRepository.getMaintenancesByUserId(
      types: types,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
