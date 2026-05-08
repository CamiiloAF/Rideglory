import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/core/services/vehicle_preferences_service.dart';
import 'package:rideglory/features/vehicles/domain/models/user_main_vehicle_model.dart';

/// Service to manage user's main vehicle preference
///
/// Stores main vehicle selection in a dedicated 'userMainVehicle' collection
/// with userId and mainVehicleId fields
@injectable
class UserMainVehicleService {
  final AuthService _authService;
  final VehiclePreferencesService _vehiclePreferencesService;

  UserMainVehicleService(this._authService, this._vehiclePreferencesService);

  /// Get the main vehicle preference for the current user
  /// Returns Either with DomainException on failure or UserMainVehicleModel
  Future<Either<DomainException, UserMainVehicleModel?>>
  getMainVehicle() async {
    return executeService<UserMainVehicleModel?>(
      function: () async {
        final userId = _authService.currentUser?.id;
        if (userId == null) {
          return null;
        }

        final mainVehicleId = await _vehiclePreferencesService
            .getSelectedVehicleId();
        if (mainVehicleId == null) {
          return null;
        }

        return UserMainVehicleModel(
          userId: userId,
          mainVehicleId: mainVehicleId,
        );
      },
    );
  }

  /// Get only the main vehicle ID for the current user
  /// Returns Either with DomainException on failure or the vehicle ID (nullable)
  Future<Either<DomainException, String?>> getMainVehicleId() async {
    return executeService<String?>(
      function: () async {
        final userId = _authService.currentUser?.id;
        if (userId == null) {
          return null;
        }

        return _vehiclePreferencesService.getSelectedVehicleId();
      },
    );
  }

  /// Set the main vehicle for the current user
  /// Creates or updates the document in the userMainVehicle collection
  Future<Either<DomainException, UserMainVehicleModel>> setMainVehicleId(
    String vehicleId,
  ) async {
    return executeService<UserMainVehicleModel>(
      function: () async {
        final userId = _authService.currentUser?.id;
        if (userId == null) {
          throw const DomainException(
            message: 'No user is currently authenticated',
          );
        }

        final userMainVehicle = UserMainVehicleModel(
          userId: userId,
          mainVehicleId: vehicleId,
          updatedAt: DateTime.now(),
        );

        await _vehiclePreferencesService.saveSelectedVehicleId(vehicleId);

        return userMainVehicle;
      },
    );
  }
}
