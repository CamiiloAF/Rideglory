import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/notifications/domain/repository/notifications_repository.dart';
import 'package:rideglory/features/notifications/domain/usecases/mark_notification_read_usecase.dart';

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

void main() {
  late MockNotificationsRepository mockRepository;
  late MarkNotificationReadUseCase useCase;

  setUp(() {
    mockRepository = MockNotificationsRepository();
    useCase = MarkNotificationReadUseCase(mockRepository);
  });

  test('camino feliz — delega el id en el repository y retorna Right', () async {
    when(() => mockRepository.markRead('n1')).thenAnswer(
      (_) async => const Right(null),
    );

    final result = await useCase('n1');

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.markRead('n1')).called(1);
  });

  test('camino de error — retorna Left cuando el repository falla', () async {
    when(() => mockRepository.markRead('n1')).thenAnswer(
      (_) async => const Left(
        DomainException(message: 'No se pudo marcar como leída'),
      ),
    );

    final result = await useCase('n1');

    expect(result.isLeft(), isTrue);
    result.fold(
      (error) => expect(error.message, 'No se pudo marcar como leída'),
      (_) => fail('Expected Left'),
    );
  });
}
