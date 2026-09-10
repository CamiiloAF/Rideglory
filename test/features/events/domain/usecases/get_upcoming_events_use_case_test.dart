import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/event.dart';
import 'package:rideglory/features/events/domain/event_difficulty.dart';
import 'package:rideglory/features/events/domain/event_state.dart';
import 'package:rideglory/features/events/domain/events_repository.dart';
import 'package:rideglory/features/events/domain/usecases/get_upcoming_events_use_case.dart';

class _MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  late _MockEventsRepository repository;
  late GetUpcomingEventsUseCase useCase;

  setUp(() {
    repository = _MockEventsRepository();
    useCase = GetUpcomingEventsUseCase(repository);
  });

  final event = Event(
    id: 'e1',
    ownerId: 'owner-1',
    ownerName: 'Camilo',
    name: 'Rodada al Nevado',
    startAt: DateTime(2026, 9, 20, 6),
    difficulty: EventDifficulty.medium,
    state: EventState.published,
    price: 0,
    approvedCount: 3,
  );

  test('delegates to the repository and returns its events', () async {
    when(
      () => repository.getUpcomingEvents(),
    ).thenAnswer((_) async => Right([event]));

    final result = await useCase();

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => const []), [event]);
    verify(() => repository.getUpcomingEvents()).called(1);
  });

  test('propagates a Left when the repository fails', () async {
    const error = DomainException(message: 'unknown_error');
    when(
      () => repository.getUpcomingEvents(),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase();

    expect(result, const Left<DomainException, List<Event>>(error));
  });
}
