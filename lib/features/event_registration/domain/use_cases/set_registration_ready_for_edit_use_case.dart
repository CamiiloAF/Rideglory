import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/repository/event_registration_repository.dart';

@injectable
class SetRegistrationReadyForEditUseCase {
  SetRegistrationReadyForEditUseCase(this._registrationRepository);

  final EventRegistrationRepository _registrationRepository;

  Future<Either<DomainException, EventRegistrationModel>> call(
    String registrationId,
  ) => _registrationRepository.setRegistrationReadyForEdit(registrationId);
}
