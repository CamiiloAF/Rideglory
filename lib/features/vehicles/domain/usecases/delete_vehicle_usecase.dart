import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/maintenance/domain/repository/maintenance_repository.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

@injectable
class DeleteVehicleUseCase {
  final VehicleRepository _vehicleRepository;
  final MaintenanceRepository _maintenanceRepository;

  DeleteVehicleUseCase(this._vehicleRepository, this._maintenanceRepository);

  Future<Either<DomainException, void>> call(String vehicleId) async {
    // First, get all maintenances associated with this vehicle
    final maintenancesResult = await _maintenanceRepository
        .getMaintenancesByVehicleId(vehicleId);

    // Delete all maintenances first
    await maintenancesResult.fold(
      (error) async {
        // Even if we can't get maintenances, continue with vehicle deletion
        return;
      },
      (maintenances) async {
        // Delete each maintenance
        for (var maintenance in maintenances) {
          if (maintenance.id != null) {
            await _maintenanceRepository.deleteMaintenance(maintenance.id!);
          }
        }
      },
    );

    // Then delete the vehicle
    return _vehicleRepository.deleteVehicle(vehicleId);
  }
}
