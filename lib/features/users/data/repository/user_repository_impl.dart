import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/users/data/dto/create_user_dto.dart';
import 'package:rideglory/features/users/data/service/user_service.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/domain/repository/user_repository.dart';

@Injectable(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._userService);

  final UserService _userService;

  @override
  Future<Either<DomainException, UserModel>> registerUser({
    required String fullName,
    required String email,
  }) {
    return executeService(
      function: () async {
        return _userService.signUp(
          CreateUserDto(fullName: fullName, email: email).toJson(),
        );
      },
    );
  }

  @override
  Future<Either<DomainException, UserModel>> getCurrentUser() {
    return executeService(function: _userService.getCurrentUser);
  }

  @override
  Future<Either<DomainException, UserModel>> getUserById(String userId) {
    return executeService(function: () => _userService.getUserById(userId));
  }

  // El receiveTimeout global de AppDio es 60s (ver
  // lib/core/http/app_dio.dart), mayor al estimado de 30-45s de la
  // orquestación de 8 pasos del backend (account-deletion.service.ts) para
  // el borrado de cuenta. No se necesita override de timeout en esta llamada.
  @override
  Future<Either<DomainException, Nothing>> deleteMyAccount() {
    return executeService(
      function: () async {
        await _userService.deleteMyAccount();
        return const Nothing();
      },
    );
  }
}
