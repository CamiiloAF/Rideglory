import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../live_ride_repository.dart';
import '../live_rider.dart';

@injectable
class WatchLiveRidersUseCase {
  const WatchLiveRidersUseCase(this._repository);

  final LiveRideRepository _repository;

  Stream<Either<DomainException, List<LiveRider>>> call(String eventId) =>
      _repository.watchRiders(eventId);
}
