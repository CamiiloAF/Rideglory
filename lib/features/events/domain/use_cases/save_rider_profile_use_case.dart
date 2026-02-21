import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/rider_profile_model.dart';
import 'package:rideglory/features/events/domain/repository/rider_profile_repository.dart';

@injectable
class SaveRiderProfileUseCase {
  SaveRiderProfileUseCase(this._riderProfileRepository);

  final RiderProfileRepository _riderProfileRepository;

  Future<Either<DomainException, RiderProfileModel>> call(
    RiderProfileModel profile,
  ) => _riderProfileRepository.saveRiderProfile(profile);
}
