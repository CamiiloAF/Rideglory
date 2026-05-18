import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/notifications/data/service/notifications_service.dart';
import 'package:rideglory/features/notifications/domain/repository/notifications_repository.dart';

@Injectable(as: NotificationsRepository)
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._service);

  final NotificationsService _service;

  @override
  Future<Either<DomainException, NotificationsPage>> getNotifications({
    String? cursor,
    int limit = 20,
  }) async {
    return executeService(
      function: () async {
        final dto = await _service.getNotifications(
          cursor: cursor,
          limit: limit,
        );
        return NotificationsPage(
          data: dto.data.map((notification) => notification.toModel()).toList(),
          nextCursor: dto.nextCursor,
        );
      },
    );
  }

  @override
  Future<Either<DomainException, void>> markRead(
    String notificationId,
  ) async {
    return executeService(
      function: () => _service.markRead(notificationId),
    );
  }

  @override
  Future<Either<DomainException, void>> markAllRead() async {
    return executeService(function: _service.markAllRead);
  }

  @override
  Future<Either<DomainException, void>> registerFcmToken(
    String token,
  ) async {
    return executeService(
      function: () => _service.registerFcmToken({'fcmToken': token}),
    );
  }
}
