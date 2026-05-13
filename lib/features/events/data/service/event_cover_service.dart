import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/features/events/data/dto/cover_generation_dto.dart';

part 'event_cover_service.g.dart';

@singleton
@RestApi()
abstract class EventCoverService {
  @factoryMethod
  factory EventCoverService(Dio dio) = _EventCoverService;

  @POST(ApiRoutes.generateEventCover)
  Future<CoverGenerationDto> generateCover(@Body() Map<String, dynamic> body);
}
