import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/repository/event_registration_repository.dart';

@injectable
class CancelEventRegistrationUseCase {
  CancelEventRegistrationUseCase(this._registrationRepository);

  final EventRegistrationRepository _registrationRepository;

  Future<Either<DomainException, Nothing>> call(String registrationId) =>
      _registrationRepository.cancelRegistration(registrationId);
}
