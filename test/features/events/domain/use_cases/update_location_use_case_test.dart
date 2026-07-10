import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/update_location_request.dart';
import 'package:rideglory/features/events/domain/repository/tracking_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/update_location_use_case.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

void main() {
  late MockTrackingRepository mockRepository;
  late UpdateLocationUseCase useCase;

  const request = UpdateLocationRequest(
    eventId: 'event-1',
    userId: 'user-1',
    latitude: 4.65,
    longitude: -74.05,
    speedKmh: 32.5,
    distanceMeters: 1200,
    batteryPercent: 80,
  );

  setUpAll(() {
    registerFallbackValue(request);
  });

  setUp(() {
    mockRepository = MockTrackingRepository();
    useCase = UpdateLocationUseCase(mockRepository);
  });

  test('delegates to repository.updateLocation and returns Right', () async {
    when(
      () => mockRepository.updateLocation(any()),
    ).thenAnswer((_) async => const Right(Nothing()));

    final result = await useCase(request);

    expect(result.isRight(), isTrue);
    verify(() => mockRepository.updateLocation(request)).called(1);
  });

  test('returns Left when repository fails', () async {
    const error = DomainException(message: 'No se pudo actualizar la ubicación.');
    when(
      () => mockRepository.updateLocation(any()),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase(request);

    expect(result, const Left(error));
  });
}
