import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../event_vehicle_option.dart';
import '../events_repository.dart';

@injectable
class GetMyVehiclesForEventUseCase {
  const GetMyVehiclesForEventUseCase(this._repository);

  final EventsRepository _repository;

  Future<Either<DomainException, List<EventVehicleOption>>> call() =>
      _repository.getMyVehicles();
}
