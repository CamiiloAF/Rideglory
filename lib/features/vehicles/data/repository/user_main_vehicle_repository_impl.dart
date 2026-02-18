import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/user_main_vehicle_service.dart';
import 'package:rideglory/features/vehicles/domain/models/user_main_vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/user_main_vehicle_repository.dart';

@Injectable(as: UserMainVehicleRepository)
class UserMainVehicleRepositoryImpl implements UserMainVehicleRepository {
  final UserMainVehicleService _userMainVehicleService;

  UserMainVehicleRepositoryImpl(this._userMainVehicleService);

  @override
  Future<Either<DomainException, UserMainVehicleModel?>> getMainVehicle() {
    return _userMainVehicleService.getMainVehicle();
  }

  @override
  Future<Either<DomainException, String?>> getMainVehicleId() {
    return _userMainVehicleService.getMainVehicleId();
  }

  @override
  Future<Either<DomainException, UserMainVehicleModel>> setMainVehicleId(
    String vehicleId,
  ) {
    return _userMainVehicleService.setMainVehicleId(vehicleId);
  }
}
