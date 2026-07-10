import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/repository/tracking_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/stop_tracking_use_case.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

void main() {
  late MockTrackingRepository mockRepository;
  late StopTrackingUseCase useCase;

  setUp(() {
    mockRepository = MockTrackingRepository();
    useCase = StopTrackingUseCase(mockRepository);
  });

  test('delegates to repository.stopTracking and returns Right', () async {
    when(
      () => mockRepository.stopTracking(
        eventId: 'event-1',
        userId: 'user-1',
      ),
    ).thenAnswer((_) async => const Right(Nothing()));

    final result = await useCase(eventId: 'event-1', userId: 'user-1');

    expect(result.isRight(), isTrue);
    verify(
      () => mockRepository.stopTracking(eventId: 'event-1', userId: 'user-1'),
    ).called(1);
  });

  test('returns Left when repository fails', () async {
    const error = DomainException(message: 'No se pudo detener el tracking.');
    when(
      () => mockRepository.stopTracking(
        eventId: any(named: 'eventId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase(eventId: 'event-1', userId: 'user-1');

    expect(result, const Left(error));
  });
}
