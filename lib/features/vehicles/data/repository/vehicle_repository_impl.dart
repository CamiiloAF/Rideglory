import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/vehicles/data/dto/vehicle_dto.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';

@Injectable(as: VehicleRepository)
class VehicleRepositoryImpl implements VehicleRepository {
  VehicleRepositoryImpl(this.firestore, this._authService);

  final FirebaseFirestore firestore;
  final AuthService _authService;

  static const _collectionName = 'vehicles';

  @override
  Future<Either<DomainException, List<VehicleModel>>>
  getVehiclesByUserId() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      throw DomainException(message: 'No user is currently authenticated.');
    }

    return executeService(
      function: () async {
        final doc = await firestore
            .collection(_collectionName)
            .where('userId', isEqualTo: userId)
            .orderBy('createdDate', descending: true)
            .get();

        if (doc.docs.isNotEmpty) {
          return doc.docs
              .map((e) => VehicleDto.fromJson(e.data()).toModel())
              .toList();
        } else {
          return [];
        }
      },
    );
  }

  @override
  Future<Either<DomainException, VehicleModel>> addVehicle(
    VehicleModel vehicle,
  ) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      throw DomainException(message: 'No user is currently authenticated.');
    }

    final now = DateTime.now();
    final vehicleId = firestore.collection(_collectionName).doc().id;

    final vehicleWithMetadata = vehicle.copyWith(
      id: vehicleId,
      createdDate: now,
      updatedDate: now,
    );

    return executeService(
      function: () async {
        final docData = vehicleWithMetadata.toJson();
        docData['userId'] = userId;

        await firestore.collection(_collectionName).doc(vehicleId).set(docData);

        return vehicleWithMetadata;
      },
    );
  }

  @override
  Future<Either<DomainException, VehicleModel>> updateVehicle(
    VehicleModel vehicle,
  ) async {
    if (vehicle.id == null) {
      throw DomainException(message: 'Vehicle ID is required for update.');
    }

    final updatedVehicle = vehicle.copyWith(updatedDate: DateTime.now());

    return executeService(
      function: () async {
        await firestore
            .collection(_collectionName)
            .doc(updatedVehicle.id)
            .update(updatedVehicle.toJson());

        return updatedVehicle;
      },
    );
  }

  @override
  Future<Either<DomainException, void>> deleteVehicle(String id) async {
    return executeService(
      function: () async {
        await firestore.collection(_collectionName).doc(id).delete();
      },
    );
  }
}
