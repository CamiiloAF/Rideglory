import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/data/dto/rider_profile_dto.dart';
import 'package:rideglory/features/events/domain/model/rider_profile_model.dart';
import 'package:rideglory/features/events/domain/repository/rider_profile_repository.dart';

@Injectable(as: RiderProfileRepository)
class RiderProfileRepositoryImpl implements RiderProfileRepository {
  RiderProfileRepositoryImpl(this._firestore, this._authService);

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  static const _collectionName = 'rider_profiles';

  @override
  Future<Either<DomainException, RiderProfileModel?>> getMyRiderProfile() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return Future.value(
        Left(DomainException(message: 'No user is currently authenticated.')),
      );
    }

    return executeService(
      function: () async {
        final doc = await _firestore
            .collection(_collectionName)
            .doc(userId)
            .get();

        if (!doc.exists || doc.data() == null) return null;

        return RiderProfileDto.fromJson(doc.data()!).copyWith(id: doc.id);
      },
    );
  }

  @override
  Future<Either<DomainException, RiderProfileModel>> saveRiderProfile(
    RiderProfileModel profile,
  ) {
    final userId = _authService.currentUser?.uid ?? profile.userId;
    final updated = profile.copyWith(
      userId: userId,
      updatedDate: DateTime.now(),
    );

    return executeService(
      function: () async {
        await _firestore
            .collection(_collectionName)
            .doc(userId)
            .set(updated.toJson(), SetOptions(merge: true));
        return updated;
      },
    );
  }
}
