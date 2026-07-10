import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/notifications/domain/repository/notifications_repository.dart';
import 'package:rideglory/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

void main() {
  late MockNotificationsRepository mockRepository;
  late MarkAllNotificationsReadUseCase useCase;

  setUp(() {
    mockRepository = MockNotificationsRepository();
    useCase = MarkAllNotificationsReadUseCase(mockRepository);
  });

  test('camino feliz — delega en el repository y retorna Right', () async {
    when(() => mockRepository.markAllRead()).thenAnswer(
      (_) async => const Right(null),
    );

    final result = await useCase();

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.markAllRead()).called(1);
  });

  test('camino de error — retorna Left cuando el repository falla', () async {
    when(() => mockRepository.markAllRead()).thenAnswer(
      (_) async => const Left(
        DomainException(message: 'No se pudo marcar todas como leídas'),
      ),
    );

    final result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold(
      (error) => expect(error.message, 'No se pudo marcar todas como leídas'),
      (_) => fail('Expected Left'),
    );
  });
}
