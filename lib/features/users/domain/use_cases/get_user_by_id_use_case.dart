import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/domain/repository/user_repository.dart';

@injectable
class GetUserByIdUseCase {
  GetUserByIdUseCase(this._userRepository);

  final UserRepository _userRepository;

  Future<Either<DomainException, UserModel>> call(String userId) =>
      _userRepository.getUserById(userId);
}
