import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/create_event_use_case.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepository;
  late CreateEventUseCase useCase;

  final event = EventModel(
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
    useCase = CreateEventUseCase(mockRepository);
  });

  test('delegates to repository.createEvent and returns Right on success', () async {
    final created = event.copyWith(id: 'event-1');
    when(
      () => mockRepository.createEvent(any()),
    ).thenAnswer((_) async => Right(created));

    final result = await useCase(event);

    expect(result, Right(created));
    verify(() => mockRepository.createEvent(event)).called(1);
  });

  test('returns Left when repository fails', () async {
    const error = DomainException(message: 'No se pudo crear el evento.');
    when(
      () => mockRepository.createEvent(any()),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase(event);

    expect(result, const Left(error));
  });
}
