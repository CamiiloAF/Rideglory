import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../profile_repository.dart';

@injectable
class DeleteAccountUseCase {
  DeleteAccountUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<DomainException, void>> call() => _repository.deleteAccount();
}
