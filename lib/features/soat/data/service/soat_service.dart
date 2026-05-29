import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/features/soat/data/dto/soat_dto.dart';

part 'soat_service.g.dart';

@singleton
@RestApi()
abstract class SoatService {
  @factoryMethod
  factory SoatService(Dio dio) = _SoatService;

  @GET('${ApiRoutes.vehicles}/{vehicleId}/soat')
  Future<SoatDto> getSoat(@Path('vehicleId') String vehicleId);

  @POST('${ApiRoutes.vehicles}/{vehicleId}/soat')
  Future<SoatDto> saveSoat(
    @Path('vehicleId') String vehicleId,
    @Body() Map<String, dynamic> request,
  );

  @DELETE('${ApiRoutes.vehicles}/{vehicleId}/soat')
  Future<void> deleteSoat(@Path('vehicleId') String vehicleId);
}
