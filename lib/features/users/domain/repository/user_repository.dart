import 'package:dartz/dartz.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

abstract class UserRepository {
  Future<Either<DomainException, UserModel>> registerUser({
    required String fullName,
    required String email,
  });

  Future<Either<DomainException, UserModel>> getCurrentUser();

  Future<Either<DomainException, UserModel>> getUserById(String userId);
}
