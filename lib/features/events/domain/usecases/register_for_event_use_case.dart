import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../events_repository.dart';
import '../register_for_event_params.dart';

@injectable
class RegisterForEventUseCase {
  const RegisterForEventUseCase(this._repository);

  final EventsRepository _repository;

  Future<Either<DomainException, Unit>> call(RegisterForEventParams params) =>
      _repository.registerForEvent(params);
}
