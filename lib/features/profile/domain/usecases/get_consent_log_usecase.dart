import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../consent_entry.dart';
import '../profile_repository.dart';

@injectable
class GetConsentLogUseCase {
  GetConsentLogUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<DomainException, List<ConsentEntry>>> call() {
    return _repository.getConsentLog();
  }
}
