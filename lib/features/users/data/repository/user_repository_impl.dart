import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/users/data/dto/create_user_dto.dart';
import 'package:rideglory/features/users/data/dto/user_dto.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/domain/repository/user_repository.dart';

@Injectable(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<DomainException, UserModel>> registerUser({
    required String fullName,
    required String email,
  }) {
    return executeService(
      function: () async {
        final response = await _dio.post<Map<String, dynamic>>(
          ApiRoutes.signUp,
          data: CreateUserDto(fullName: fullName, email: email).toJson(),
        );

        final data = response.data;
        if (data == null) {
          throw const DomainException(
            message: 'No pudimos crear tu usuario. Intenta nuevamente.',
          );
        }

        return UserDto.fromJson(data);
      },
    );
  }
}
