import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../sos_alert.dart';
import '../sos_repository.dart';

@injectable
class WatchSosAlertsUseCase {
  const WatchSosAlertsUseCase(this._repository);

  final SosRepository _repository;

  Stream<Either<DomainException, List<SosAlert>>> call(String eventId) =>
      _repository.watchAlerts(eventId);
}
