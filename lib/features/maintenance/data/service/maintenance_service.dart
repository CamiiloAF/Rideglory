import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/features/maintenance/data/dto/maintenance_dto.dart';
import 'package:rideglory/features/maintenance/data/dto/vehicle_maintenances_list_response_dto.dart';

part 'maintenance_service.g.dart';

@singleton
@RestApi()
abstract class MaintenanceService {
  @factoryMethod
  factory MaintenanceService(Dio dio) = _MaintenanceService;

  @GET('${ApiRoutes.maintenances}/vehicle/{vehicleId}')
  Future<VehicleMaintenancesListResponseDto> getByVehicleId(
    @Path('vehicleId') String vehicleId, {
    @Queries() Map<String, dynamic>? filter,
  });

  @POST('${ApiRoutes.maintenances}/vehicle/{vehicleId}')
  Future<MaintenanceDto> create(
    @Path('vehicleId') String vehicleId,
    @Body() Map<String, dynamic> body,
  );

  @PATCH('${ApiRoutes.maintenances}/vehicle/{vehicleId}/{id}')
  Future<MaintenanceDto> update(
    @Path('vehicleId') String vehicleId,
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${ApiRoutes.maintenances}/vehicle/{vehicleId}/{id}')
  Future<void> delete(
    @Path('vehicleId') String vehicleId,
    @Path('id') String id,
  );
}
