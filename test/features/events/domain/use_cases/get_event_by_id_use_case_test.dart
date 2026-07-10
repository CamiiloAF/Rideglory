import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_by_id_use_case.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late GetEventByIdUseCase useCase;

  final event = EventModel(
    id: 'event-1',
    ownerId: 'owner-1',
    name: 'Rodada nocturna',
    description: 'Una rodada',
    startDate: DateTime(2026, 8, 1),
    difficulty: EventDifficulty.two,
    meetingTime: DateTime(2026, 8, 1, 18),
    eventType: EventType.onRoad,
  );

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = GetEventByIdUseCase(mockRepository);
  });

  test('delegates to repository.getEventById and returns Right', () async {
    when(
      () => mockRepository.getEventById('event-1'),
    ).thenAnswer((_) async => Right(event));

    final result = await useCase('event-1');

    expect(result, Right(event));
    verify(() => mockRepository.getEventById('event-1')).called(1);
  });

  test('returns Left when event is not found', () async {
    const error = DomainException(message: 'No encontramos el evento.');
    when(
      () => mockRepository.getEventById('missing'),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase('missing');

    expect(result, const Left(error));
  });
}
