import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:rideglory/core/http/api_routes.dart';
import 'package:rideglory/features/notifications/data/dto/notification_dto.dart';

part 'notifications_service.g.dart';

@singleton
@RestApi()
abstract class NotificationsService {
  @factoryMethod
  factory NotificationsService(Dio dio) = _NotificationsService;

  @GET(ApiRoutes.notifications)
  Future<NotificationPageDto> getNotifications({
    @Query('cursor') String? cursor,
    @Query('limit') int limit = 20,
  });

  @PATCH('{notificationId}/read')
  Future<void> markRead(
    @Path('notificationId') String notificationId,
  );

  @PATCH(ApiRoutes.notificationsReadAll)
  Future<void> markAllRead();

  @POST(ApiRoutes.notificationsFcmToken)
  Future<void> registerFcmToken(
    @Body() Map<String, dynamic> body,
  );
}
