import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/notifications/domain/repository/notifications_repository.dart';

@injectable
class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Either<DomainException, NotificationsPage>> call({
    String? cursor,
    int limit = 20,
  }) {
    return _repository.getNotifications(cursor: cursor, limit: limit);
  }
}
