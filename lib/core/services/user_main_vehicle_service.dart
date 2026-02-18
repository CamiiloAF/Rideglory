import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/vehicles/data/dto/user_main_vehicle_dto.dart';
import 'package:rideglory/features/vehicles/domain/models/user_main_vehicle_model.dart';

/// Service to manage user's main vehicle preference
///
/// Stores main vehicle selection in a dedicated 'userMainVehicle' collection
/// with userId and mainVehicleId fields
@injectable
class UserMainVehicleService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  static const _collectionName = 'userMainVehicle';

  UserMainVehicleService(this._firestore, this._authService);

  /// Get the main vehicle preference for the current user
  /// Returns Either with DomainException on failure or UserMainVehicleModel
  Future<Either<DomainException, UserMainVehicleModel?>>
  getMainVehicle() async {
    return executeService<UserMainVehicleModel?>(
      function: () async {
        final userId = _authService.currentUser?.uid;
        if (userId == null) {
          return null;
        }

        final doc = await _firestore
            .collection(_collectionName)
            .doc(userId)
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            return UserMainVehicleDto.fromJson(data).toModel();
          }
        }
        return null;
      },
    );
  }

  /// Get only the main vehicle ID for the current user
  /// Returns Either with DomainException on failure or the vehicle ID (nullable)
  Future<Either<DomainException, String?>> getMainVehicleId() async {
    return executeService<String?>(
      function: () async {
        final userId = _authService.currentUser?.uid;
        if (userId == null) {
          return null;
        }

        final doc = await _firestore
            .collection(_collectionName)
            .doc(userId)
            .get();

        if (doc.exists) {
          return doc.data()?['mainVehicleId'] as String?;
        }
        return null;
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
        final userId = _authService.currentUser?.uid;
        if (userId == null) {
          throw DomainException(message: 'No user is currently authenticated');
        }

        final userMainVehicle = UserMainVehicleModel(
          userId: userId,
          mainVehicleId: vehicleId,
          updatedAt: DateTime.now(),
        );

        final data = userMainVehicle.toJson();

        await _firestore.collection(_collectionName).doc(userId).set(data);

        return userMainVehicle;
      },
    );
  }
}
