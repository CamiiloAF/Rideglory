import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/notifications/domain/repository/notifications_repository.dart';

@injectable
class MarkNotificationReadUseCase {
  MarkNotificationReadUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Either<DomainException, void>> call(String notificationId) {
    return _repository.markRead(notificationId);
  }
}
