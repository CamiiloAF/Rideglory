import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

@injectable
class UnarchiveVehicleUseCase {
  final VehicleRepository _repository;

  UnarchiveVehicleUseCase(this._repository);

  Future<Either<DomainException, VehicleModel>> call(
    VehicleModel vehicle,
  ) async {
    final unarchivedVehicle = vehicle.copyWith(
      isArchived: false,
      updatedDate: DateTime.now(),
    );
    return _repository.updateVehicle(unarchivedVehicle);
  }
}
