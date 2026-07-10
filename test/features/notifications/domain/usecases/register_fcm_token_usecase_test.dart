import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/notifications/domain/repository/notifications_repository.dart';
import 'package:rideglory/features/notifications/domain/usecases/register_fcm_token_usecase.dart';

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockNotificationsRepository mockRepository;
  late MockAnalyticsService mockAnalytics;
  late RegisterFcmTokenUseCase useCase;

  setUp(() {
    mockRepository = MockNotificationsRepository();
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    useCase = RegisterFcmTokenUseCase(mockRepository, mockAnalytics);
  });

  test(
    'camino feliz — registra el token, retorna Right y loguea fcm_token_registered',
    () async {
      when(() => mockRepository.registerFcmToken('token-123')).thenAnswer(
        (_) async => const Right(null),
      );

      final result = await useCase('token-123');

      expect(result.isRight(), isTrue);
      verify(() => mockRepository.registerFcmToken('token-123')).called(1);
      verify(
        () => mockAnalytics.logEvent(AnalyticsEvents.fcmTokenRegistered),
      ).called(1);
    },
  );

  test(
    'el token nunca se loguea como parámetro de analytics (PII)',
    () async {
      when(() => mockRepository.registerFcmToken('token-123')).thenAnswer(
        (_) async => const Right(null),
      );

      await useCase('token-123');

      final captured = verify(
        () => mockAnalytics.logEvent(captureAny()),
      ).captured;
      expect(captured, isNot(contains('token-123')));
    },
  );

  test(
    'camino de error — retorna Left y NO loguea el evento de analytics',
    () async {
      when(() => mockRepository.registerFcmToken('token-123')).thenAnswer(
        (_) async =>
            const Left(DomainException(message: 'No se pudo registrar')),
      );

      final result = await useCase('token-123');

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, 'No se pudo registrar'),
        (_) => fail('Expected Left'),
      );
      verifyNever(
        () => mockAnalytics.logEvent(AnalyticsEvents.fcmTokenRegistered),
      );
    },
  );
}
