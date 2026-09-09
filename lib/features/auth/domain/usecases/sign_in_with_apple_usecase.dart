import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../auth_repository.dart';

@injectable
class SignInWithAppleUseCase {
  SignInWithAppleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<DomainException, void>> call() {
    return _repository.signInWithApple();
  }
}
