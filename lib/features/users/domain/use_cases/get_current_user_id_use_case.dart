import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/auth_service.dart';

@injectable
class GetCurrentUserIdUseCase {
  const GetCurrentUserIdUseCase(this._authService);

  final AuthService _authService;

  Future<Either<DomainException, String>> call() {
    return _authService.getCurrentUserId();
  }
}
