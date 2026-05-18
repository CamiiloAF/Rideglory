import 'package:dartz/dartz.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/notifications/domain/model/notification_model.dart';

class NotificationsPage {
  const NotificationsPage({required this.data, this.nextCursor});

  final List<NotificationModel> data;
  final String? nextCursor;
}

abstract class NotificationsRepository {
  Future<Either<DomainException, NotificationsPage>> getNotifications({
    String? cursor,
    int limit = 20,
  });

  Future<Either<DomainException, void>> markRead(String notificationId);

  Future<Either<DomainException, void>> markAllRead();

  Future<Either<DomainException, void>> registerFcmToken(String token);
}
