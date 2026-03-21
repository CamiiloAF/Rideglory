import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/domain/repository/tracking_repository.dart';

@injectable
class StartTrackingUseCase {
  StartTrackingUseCase(this._trackingRepository);

  final TrackingRepository _trackingRepository;

  Future<Either<DomainException, Nothing>> call({
    required String eventId,
    required RiderTrackingModel initialData,
  }) =>
      _trackingRepository.startTracking(
        eventId: eventId,
        initialData: initialData,
      );
}
