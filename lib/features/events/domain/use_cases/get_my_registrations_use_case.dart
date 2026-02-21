import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/repository/event_registration_repository.dart';

@injectable
class GetMyRegistrationsUseCase {
  GetMyRegistrationsUseCase(this._registrationRepository);

  final EventRegistrationRepository _registrationRepository;

  Future<Either<DomainException, List<EventRegistrationModel>>> call() =>
      _registrationRepository.getMyRegistrations();
}
