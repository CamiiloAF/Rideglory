import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../profile.dart';
import '../profile_repository.dart';

@injectable
class GetProfileUseCase {
  GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<DomainException, Profile>> call() => _repository.getProfile();
}
