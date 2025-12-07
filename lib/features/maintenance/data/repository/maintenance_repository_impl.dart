import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../../../../core/http/rest_client_functions.dart';
import '../../domain/repository/maintenance_repository.dart';
import '../dto/maintenance_dto.dart';

@Injectable(as: MaintenanceRepository)
class MaintenanceRepositoryImpl implements MaintenanceRepository {
  MaintenanceRepositoryImpl(this.firestore);

  final FirebaseFirestore firestore;

  static const _collectionName = 'users';

  @override
  Future<Either<DomainException, List<MaintenanceModel>>>
  getMaintenancesByUserId(String userId) async {
    return executeService(
      function: () async {
        final doc = await firestore
            .collection(_collectionName)
            .doc(userId)
            .get();
        if (doc.exists) {
          // return UserDto.fromJson(doc.data()!).toDomainModel();
          return [];
        } else {
          throw DomainException(message: 'No existe el registro.');
        }
      },
    );
  }

  @override
  Future<Either<DomainException, MaintenanceModel>> addMaintenance(
    MaintenanceModel maintenance,
  ) async {
    return executeService(
      function: () async {
        await firestore
            .collection(_collectionName)
            .doc(maintenance.id)
            .set(maintenance.toJson());

        return maintenance;
      },
    );
  }

  @override
  Future<Either<DomainException, MaintenanceModel>> deleteMaintenance(
    String id,
  ) {
    // TODO: implement deleteMaintenance
    throw UnimplementedError();
  }

  @override
  Future<Either<DomainException, MaintenanceModel>> updateMaintenance(
    MaintenanceModel maintenance,
  ) async {
    return executeService(
      function: () async {
        await firestore
            .collection(_collectionName)
            .doc(maintenance.id)
            .update(maintenance.toJson());

        return maintenance;
      },
    );
  }
}
