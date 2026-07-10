import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/get_events_use_case.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late GetEventsUseCase useCase;

  final events = [
    EventModel(
      id: 'event-1',
      ownerId: 'owner-1',
      name: 'Rodada nocturna',
      description: 'Una rodada',
      startDate: DateTime(2026, 8, 1),
      difficulty: EventDifficulty.two,
      meetingTime: DateTime(2026, 8, 1, 18),
      eventType: EventType.onRoad,
    ),
  ];

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = GetEventsUseCase(mockRepository);
  });

  test('delegates filters to repository.getEvents and returns Right', () async {
    when(
      () => mockRepository.getEvents(
        type: 'ON_ROAD',
        dateFrom: '2026-08-01',
        dateTo: '2026-08-31',
      ),
    ).thenAnswer((_) async => Right(events));

    final result = await useCase(
      type: 'ON_ROAD',
      dateFrom: '2026-08-01',
      dateTo: '2026-08-31',
    );

    expect(result, Right(events));
    verify(
      () => mockRepository.getEvents(
        type: 'ON_ROAD',
        dateFrom: '2026-08-01',
        dateTo: '2026-08-31',
      ),
    ).called(1);
  });

  test('returns Left when repository fails', () async {
    const error = DomainException(message: 'No se pudieron cargar eventos.');
    when(
      () => mockRepository.getEvents(
        type: any(named: 'type'),
        dateFrom: any(named: 'dateFrom'),
        dateTo: any(named: 'dateTo'),
      ),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase();

    expect(result, const Left(error));
  });
}
