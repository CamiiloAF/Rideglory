import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../models/vehicle_model.dart';

/// Use case to initialize authenticated user's vehicles
/// 
/// This use case:
/// 1. Loads all vehicles for the current user
/// 2. Returns the list for pre-setting in VehicleCubit
/// 
/// Call this after successful login/signup in AuthCubit
@injectable
class InitializeAuthenticatedUserVehiclesUseCase {
  final VehicleRepository _vehicleRepository;

  InitializeAuthenticatedUserVehiclesUseCase(this._vehicleRepository);

  Future<Either<DomainException, List<VehicleModel>>> call() async {
    return _vehicleRepository.getVehiclesByUserId();
  }
}
