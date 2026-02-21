import 'package:dartz/dartz.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/rider_profile_model.dart';

abstract class RiderProfileRepository {
  Future<Either<DomainException, RiderProfileModel?>> getMyRiderProfile();

  Future<Either<DomainException, RiderProfileModel>> saveRiderProfile(
    RiderProfileModel profile,
  );
}
