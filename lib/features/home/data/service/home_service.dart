import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/features/home/data/dto/home_dto.dart';

part 'home_service.g.dart';

@singleton
@RestApi()
abstract class HomeService {
  @factoryMethod
  factory HomeService(Dio dio) = _HomeService;

  @GET(ApiRoutes.home)
  Future<HomeDto> getHome();
}
