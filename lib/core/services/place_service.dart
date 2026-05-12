import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:rideglory/core/http/api_routes.dart';

part 'place_service.g.dart';

@singleton
@RestApi()
abstract class PlaceService {
  @factoryMethod
  factory PlaceService(Dio dio) = _PlaceService;

  @GET(ApiRoutes.placesAutocomplete)
  Future<List<String>> autocomplete(
    @Query('q') String query,
    @Query('type') String type,
  );
}
