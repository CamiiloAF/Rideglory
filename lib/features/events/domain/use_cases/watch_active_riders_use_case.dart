import 'package:injectable/injectable.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/domain/repository/tracking_repository.dart';

@injectable
class WatchActiveRidersUseCase {
  WatchActiveRidersUseCase(this._trackingRepository);

  final TrackingRepository _trackingRepository;

  Stream<List<RiderTrackingModel>> call(String eventId) =>
      _trackingRepository.watchActiveRiders(eventId);
}
