import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/create_event_params.dart';
import 'package:rideglory/features/events/domain/event_difficulty.dart';
import 'package:rideglory/features/events/domain/events_repository.dart';
import 'package:rideglory/features/events/domain/usecases/create_event_use_case.dart';

class _MockEventsRepository extends Mock implements EventsRepository {}

void main() {
  late _MockEventsRepository repository;
  late CreateEventUseCase useCase;

  final params = CreateEventParams(
    name: 'Rodada al Nevado',
    startAt: DateTime(2026, 9, 20, 6),
    meetingPoint: 'Estación Terpel Sur',
    destinationName: 'Manizales, Caldas',
    destinationLat: 5.06,
    destinationLng: -75.51,
    routeText: 'Autopista Sur hasta Chinchiná',
    difficulty: EventDifficulty.medium,
    maxParticipants: 20,
    price: 0,
  );

  setUp(() {
    repository = _MockEventsRepository();
    useCase = CreateEventUseCase(repository);
  });

  test('creates a draft and publishes it without a photo', () async {
    when(
      () => repository.createEvent(params),
    ).thenAnswer((_) async => const Right('event-1'));
    when(
      () => repository.publishEvent('event-1'),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase(params);

    expect(result, const Right<DomainException, Unit>(unit));
    verifyNever(() => repository.uploadEventImage(any(), any()));
    verify(() => repository.publishEvent('event-1')).called(1);
  });

  test('uploads the photo before publishing when provided', () async {
    final withPhoto = params.copyWith(localImagePath: '/tmp/cover.jpg');
    when(
      () => repository.createEvent(withPhoto),
    ).thenAnswer((_) async => const Right('event-2'));
    when(
      () => repository.uploadEventImage('event-2', '/tmp/cover.jpg'),
    ).thenAnswer((_) async => const Right('owner/event-2.jpg'));
    when(
      () => repository.publishEvent('event-2'),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase(withPhoto);

    expect(result, const Right<DomainException, Unit>(unit));
    verify(
      () => repository.uploadEventImage('event-2', '/tmp/cover.jpg'),
    ).called(1);
  });

  test('stops and returns Left when creating the draft fails', () async {
    const error = DomainException(message: 'unknown_error');
    when(
      () => repository.createEvent(params),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase(params);

    expect(result, const Left<DomainException, Unit>(error));
    verifyNever(() => repository.publishEvent(any()));
  });
}
