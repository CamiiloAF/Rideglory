import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/repository/tracking_repository.dart';

@injectable
class StopTrackingUseCase {
  StopTrackingUseCase(this._trackingRepository);

  final TrackingRepository _trackingRepository;

  Future<Either<DomainException, Nothing>> call({
    required String eventId,
    required String userId,
  }) =>
      _trackingRepository.stopTracking(eventId: eventId, userId: userId);
}
