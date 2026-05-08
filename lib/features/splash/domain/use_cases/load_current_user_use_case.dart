import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

@injectable
class LoadCurrentUserUseCase {
  const LoadCurrentUserUseCase(this._authService);

  final AuthService _authService;

  Future<Either<DomainException, UserModel?>> call() {
    return _authService.loadCurrentUser();
  }
}
