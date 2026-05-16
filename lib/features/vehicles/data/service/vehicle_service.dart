import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/features/vehicles/data/dto/soat_dto.dart';
import 'package:rideglory/features/vehicles/data/dto/vehicle_dto.dart';

part 'vehicle_service.g.dart';

@singleton
@RestApi()
abstract class VehicleService {
  @factoryMethod
  factory VehicleService(Dio dio) = _VehicleService;

  @GET(ApiRoutes.myVehicles)
  Future<List<VehicleDto>> getMyVehicles();

  @PUT('${ApiRoutes.myVehicles}/{vehicleId}/main')
  Future<VehicleDto> setMyMainVehicle(@Path('vehicleId') String vehicleId);

  @POST(ApiRoutes.myVehicles)
  Future<VehicleDto> createMyVehicle(@Body() Map<String, dynamic> request);

  @PATCH('${ApiRoutes.vehicles}/{id}')
  Future<VehicleDto> updateVehicle(
    @Path('id') String id,
    @Body() Map<String, dynamic> request,
  );

  @DELETE('${ApiRoutes.vehicles}/hard-delete/{id}')
  Future<void> deleteVehicle(@Path('id') String id);

  @POST('${ApiRoutes.vehicles}/{vehicleId}/soat')
  Future<SoatDto> upsertSoat(
    @Path('vehicleId') String vehicleId,
    @Body() Map<String, dynamic> body,
  );

  @GET('${ApiRoutes.vehicles}/{vehicleId}/soat')
  Future<SoatDto> getSoat(@Path('vehicleId') String vehicleId);
}
