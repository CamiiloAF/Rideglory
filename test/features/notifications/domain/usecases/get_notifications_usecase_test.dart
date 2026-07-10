import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/notifications/domain/model/notification_model.dart';
import 'package:rideglory/features/notifications/domain/repository/notifications_repository.dart';
import 'package:rideglory/features/notifications/domain/usecases/get_notifications_usecase.dart';

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

void main() {
  late MockNotificationsRepository mockRepository;
  late GetNotificationsUseCase useCase;

  setUp(() {
    mockRepository = MockNotificationsRepository();
    useCase = GetNotificationsUseCase(mockRepository);
  });

  final notification = NotificationModel(
    id: 'n1',
    type: NotificationType.general,
    title: 'Notificación',
    body: 'Cuerpo',
    createdAt: DateTime(2026, 6, 1),
  );

  test('camino feliz — delega en el repository y retorna Right', () async {
    when(
      () => mockRepository.getNotifications(cursor: null, limit: 20),
    ).thenAnswer(
      (_) async => Right(
        NotificationsPage(data: [notification], nextCursor: 'cursor2'),
      ),
    );

    final result = await useCase();

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('Expected Right'), (page) {
      expect(page.data, [notification]);
      expect(page.nextCursor, 'cursor2');
    });
    verify(
      () => mockRepository.getNotifications(cursor: null, limit: 20),
    ).called(1);
  });

  test('propaga cursor y limit al repository', () async {
    when(
      () => mockRepository.getNotifications(cursor: 'abc', limit: 5),
    ).thenAnswer((_) async => const Right(NotificationsPage(data: [])));

    await useCase(cursor: 'abc', limit: 5);

    verify(
      () => mockRepository.getNotifications(cursor: 'abc', limit: 5),
    ).called(1);
  });

  test('camino de error — retorna Left cuando el repository falla', () async {
    when(
      () => mockRepository.getNotifications(cursor: null, limit: 20),
    ).thenAnswer(
      (_) async =>
          const Left(DomainException(message: 'No se pudo cargar')),
    );

    final result = await useCase();

    expect(result.isLeft(), isTrue);
    result.fold(
      (error) => expect(error.message, 'No se pudo cargar'),
      (_) => fail('Expected Left'),
    );
  });
}
