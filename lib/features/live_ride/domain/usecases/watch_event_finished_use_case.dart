import 'package:injectable/injectable.dart';

import '../live_ride_repository.dart';

@injectable
class WatchEventFinishedUseCase {
  const WatchEventFinishedUseCase(this._repository);

  final LiveRideRepository _repository;

  Stream<bool> call(String eventId) => _repository.watchEventFinished(eventId);
}
