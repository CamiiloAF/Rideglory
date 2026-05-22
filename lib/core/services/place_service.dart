import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/core/services/dto/geocode_result_dto.dart';
import 'package:rideglory/core/services/dto/place_suggestion_dto.dart';

part 'place_service.g.dart';

@singleton
@RestApi()
abstract class PlaceService {
  @factoryMethod
  factory PlaceService(Dio dio) = _PlaceService;

  @GET(ApiRoutes.placesAutocomplete)
  Future<List<PlaceSuggestionDto>> autocomplete(
    @Query('q') String query,
    @Query('type') String type,
  );

  @GET(ApiRoutes.placesDetails)
  Future<GeocodeResultDto> details(@Query('placeId') String placeId);

  @GET(ApiRoutes.placesGeocode)
  Future<GeocodeResultDto> geocode(@Query('q') String address);
}
