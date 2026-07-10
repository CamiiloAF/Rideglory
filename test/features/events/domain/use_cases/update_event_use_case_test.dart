import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late UpdateEventUseCase useCase;

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

  setUpAll(() {
    registerFallbackValue(event);
  });

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = UpdateEventUseCase(mockRepository);
  });

  test('delegates to repository.updateEvent and returns Right on success', () async {
    when(
      () => mockRepository.updateEvent(any()),
    ).thenAnswer((_) async => Right(event));

    final result = await useCase(event);

    expect(result, Right(event));
    verify(() => mockRepository.updateEvent(event)).called(1);
  });

  test('returns Left when repository fails', () async {
    const error = DomainException(message: 'No se pudo actualizar.');
    when(
      () => mockRepository.updateEvent(any()),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase(event);

    expect(result, const Left(error));
  });
}
