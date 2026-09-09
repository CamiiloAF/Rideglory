import 'package:injectable/injectable.dart';

import '../auth_repository.dart';

@injectable
class SignOutUseCase {
  SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}
