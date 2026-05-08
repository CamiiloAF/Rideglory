import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/features/events/data/dto/event_dto.dart';

part 'event_service.g.dart';

@singleton
@RestApi()
abstract class EventService {
  @factoryMethod
  factory EventService(Dio dio) = _EventService;

  @GET(ApiRoutes.events)
  Future<List<EventDto>> getEvents();

  @GET(ApiRoutes.myEvents)
  Future<List<EventDto>> getMyEvents();

  @GET('${ApiRoutes.events}/{id}')
  Future<EventDto> getEventById(@Path('id') String id);

  @POST(ApiRoutes.events)
  Future<EventDto> createEvent(@Body() Map<String, dynamic> request);

  @PATCH('${ApiRoutes.events}/{id}')
  Future<EventDto> updateEvent(
    @Path('id') String id,
    @Body() Map<String, dynamic> request,
  );

  @DELETE('${ApiRoutes.events}/{id}')
  Future<void> deleteEvent(@Path('id') String id);
}
