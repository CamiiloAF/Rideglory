import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/features/tecnomecanica/data/dto/tecnomecanica_dto.dart';

part 'tecnomecanica_service.g.dart';

@singleton
@RestApi()
abstract class TecnomecanicaService {
  @factoryMethod
  factory TecnomecanicaService(Dio dio) = _TecnomecanicaService;

  @GET('${ApiRoutes.vehicles}/{vehicleId}/tecnomecanica')
  Future<TecnomecanicaDto> getTecnomecanica(
    @Path('vehicleId') String vehicleId,
  );

  @POST('${ApiRoutes.vehicles}/{vehicleId}/tecnomecanica')
  Future<TecnomecanicaDto> saveTecnomecanica(
    @Path('vehicleId') String vehicleId,
    @Body() Map<String, dynamic> request,
  );

  @DELETE('${ApiRoutes.vehicles}/{vehicleId}/tecnomecanica')
  Future<void> deleteTecnomecanica(@Path('vehicleId') String vehicleId);
}
