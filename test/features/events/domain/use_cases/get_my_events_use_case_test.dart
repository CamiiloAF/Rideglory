import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_events_use_case.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late GetMyEventsUseCase useCase;

  final events = [
    EventModel(
      id: 'event-1',
      ownerId: 'owner-1',
      name: 'Mi evento',
      description: 'Una rodada',
      startDate: DateTime(2026, 8, 1),
      difficulty: EventDifficulty.two,
      meetingTime: DateTime(2026, 8, 1, 18),
      eventType: EventType.onRoad,
    ),
  ];

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = GetMyEventsUseCase(mockRepository);
  });

  test('delegates to repository.getMyEvents and returns Right', () async {
    when(
      () => mockRepository.getMyEvents(),
    ).thenAnswer((_) async => Right(events));

    final result = await useCase();

    expect(result, Right(events));
    verify(() => mockRepository.getMyEvents()).called(1);
  });

  test('returns Left when repository fails', () async {
    const error = DomainException(message: 'No se pudieron cargar tus eventos.');
    when(
      () => mockRepository.getMyEvents(),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase();

    expect(result, const Left(error));
  });
}
