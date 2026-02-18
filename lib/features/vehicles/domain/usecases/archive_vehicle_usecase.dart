import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

@injectable
class ArchiveVehicleUseCase {
  final VehicleRepository _repository;

  ArchiveVehicleUseCase(this._repository);

  Future<Either<DomainException, VehicleModel>> call(
    VehicleModel vehicle,
  ) async {
    final archivedVehicle = vehicle.copyWith(
      isArchived: true,
      updatedDate: DateTime.now(),
    );
    return _repository.updateVehicle(archivedVehicle);
  }
}
