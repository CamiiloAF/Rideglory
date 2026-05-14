import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/notifications/domain/repository/notifications_repository.dart';

@injectable
class RegisterFcmTokenUseCase {
  RegisterFcmTokenUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Either<DomainException, void>> call(String token) {
    return _repository.registerFcmToken(token);
  }
}
