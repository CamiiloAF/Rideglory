import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../profile.dart';
import '../profile_repository.dart';

@injectable
class UpdateEmergencyContactUseCase {
  UpdateEmergencyContactUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<DomainException, Profile>> call({
    required String name,
    required String phone,
    String? relationship,
  }) {
    return _repository.updateEmergencyContact(
      name: name,
      phone: phone,
      relationship: relationship,
    );
  }
}
