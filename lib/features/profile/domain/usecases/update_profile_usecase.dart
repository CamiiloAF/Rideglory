import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../blood_type.dart';
import '../profile.dart';
import '../profile_repository.dart';

@injectable
class UpdateProfileUseCase {
  UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<DomainException, Profile>> call({
    String? fullName,
    String? phone,
    DateTime? birthDate,
    String? residenceCity,
    String? eps,
    String? medicalInsurance,
    BloodType? bloodType,
  }) {
    return _repository.updateProfile(
      fullName: fullName,
      phone: phone,
      birthDate: birthDate,
      residenceCity: residenceCity,
      eps: eps,
      medicalInsurance: medicalInsurance,
      bloodType: bloodType,
    );
  }
}
