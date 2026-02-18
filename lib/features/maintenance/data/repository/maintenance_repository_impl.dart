import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../../../../core/http/rest_client_functions.dart';
import '../../domain/repository/maintenance_repository.dart';
import '../dto/maintenance_dto.dart';

@Injectable(as: MaintenanceRepository)
class MaintenanceRepositoryImpl implements MaintenanceRepository {
  MaintenanceRepositoryImpl(this.firestore, this._authService);

  final FirebaseFirestore firestore;
  final AuthService _authService;

  static const _collectionName = 'maintenances';

  @override
  Future<Either<DomainException, List<MaintenanceModel>>>
  getMaintenancesByUserId() async {
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
              .map((e) => MaintenanceDto.fromJson(e.data()).copyWith(id: e.id))
              .toList();
        } else {
          return [];
        }
      },
    );
  }

  @override
  Future<Either<DomainException, List<MaintenanceModel>>>
  getMaintenancesByVehicleId(String vehicleId) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      throw DomainException(message: 'No user is currently authenticated.');
    }

    return executeService(
      function: () async {
        final doc = await firestore
            .collection(_collectionName)
            .where('userId', isEqualTo: userId)
            .where('vehicleId', isEqualTo: vehicleId)
            .get();

        if (doc.docs.isNotEmpty) {
          return doc.docs
              .map((e) => MaintenanceDto.fromJson(e.data()).copyWith(id: e.id))
              .toList();
        } else {
          return [];
        }
      },
    );
  }

  @override
  Future<Either<DomainException, MaintenanceModel>> addMaintenance(
    MaintenanceModel maintenance,
  ) async {
    final now = DateTime.now();
    final maintenanceWithDates = maintenance.copyWith(
      userId: _authService.currentUser?.uid ?? maintenance.userId,
      createdDate: now,
      updatedDate: now,
    );

    return executeService(
      function: () async {
        await firestore
            .collection(_collectionName)
            .doc(maintenanceWithDates.id)
            .set(maintenanceWithDates.toJson());

        return maintenanceWithDates;
      },
    );
  }

  @override
  Future<Either<DomainException, Nothing>> deleteMaintenance(String id) {
    return executeService(
      function: () async {
        await firestore.collection(_collectionName).doc(id).delete();

        return Nothing();
      },
    );
  }

  @override
  Future<Either<DomainException, MaintenanceModel>> updateMaintenance(
    MaintenanceModel maintenance,
  ) async {
    final updatedMaintenance = maintenance.copyWith(
      updatedDate: DateTime.now(),
    );

    return executeService(
      function: () async {
        await firestore
            .collection(_collectionName)
            .doc(updatedMaintenance.id)
            .update(updatedMaintenance.toJson());

        return updatedMaintenance;
      },
    );
  }
}
