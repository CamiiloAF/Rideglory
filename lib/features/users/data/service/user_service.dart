import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/features/users/data/dto/user_dto.dart';

part 'user_service.g.dart';

@singleton
@RestApi()
abstract class UserService {
  @factoryMethod
  factory UserService(Dio dio) = _UserService;

  @POST(ApiRoutes.signUp)
  Future<UserDto> signUp(@Body() Map<String, dynamic> request);

  @GET(ApiRoutes.me)
  Future<UserDto> getCurrentUser();

  @GET('/users/{id}')
  Future<UserDto> getUserById(@Path('id') String id);

  @PATCH('/users/{id}')
  Future<UserDto> updateUser(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE(ApiRoutes.me)
  Future<void> deleteMyAccount();
}
