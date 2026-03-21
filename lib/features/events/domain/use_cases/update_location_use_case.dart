import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/update_location_request.dart';
import 'package:rideglory/features/events/domain/repository/tracking_repository.dart';

@injectable
class UpdateLocationUseCase {
  UpdateLocationUseCase(this._trackingRepository);

  final TrackingRepository _trackingRepository;

  Future<Either<DomainException, Nothing>> call(UpdateLocationRequest request) =>
      _trackingRepository.updateLocation(request);
}
