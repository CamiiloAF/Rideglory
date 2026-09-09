import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../auth_repository.dart';

@injectable
class SendPasswordResetUseCase {
  SendPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<DomainException, void>> call({required String email}) {
    return _repository.sendPasswordResetEmail(email: email);
  }
}
