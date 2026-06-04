import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/notifications/domain/repository/notifications_repository.dart';

@injectable
class RegisterFcmTokenUseCase {
  RegisterFcmTokenUseCase(this._repository, this._analytics);

  final NotificationsRepository _repository;
  final AnalyticsService _analytics;

  Future<Either<DomainException, void>> call(String token) async {
    final result = await _repository.registerFcmToken(token);
    // Best-effort health signal — never log the token itself (PII / high-cardinality).
    result.fold((_) {}, (_) {
      _analytics.logEvent(AnalyticsEvents.fcmTokenRegistered).ignore();
    });
    return result;
  }
}
