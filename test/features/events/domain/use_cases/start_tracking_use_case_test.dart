import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/domain/repository/tracking_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/start_tracking_use_case.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

void main() {
  late MockTrackingRepository mockRepository;
  late StartTrackingUseCase useCase;

  final initialData = RiderTrackingModel(
    userId: 'user-1',
    fullName: 'Camilo Agudelo',
    role: RiderTrackingRole.rider,
    latitude: 4.65,
    longitude: -74.05,
    speedKmh: 0,
    distanceMeters: 0,
    batteryPercent: 100,
    isActive: true,
    deviceLabel: 'iPhone',
    lastUpdated: DateTime(2026, 8, 1),
  );

  setUpAll(() {
    registerFallbackValue(initialData);
  });

  setUp(() {
    mockRepository = MockTrackingRepository();
    useCase = StartTrackingUseCase(mockRepository);
  });

  test('delegates to repository.startTracking and returns Right', () async {
    when(
      () => mockRepository.startTracking(
        eventId: any(named: 'eventId'),
        initialData: any(named: 'initialData'),
      ),
    ).thenAnswer((_) async => const Right(Nothing()));

    final result = await useCase(
      eventId: 'event-1',
      initialData: initialData,
    );

    expect(result.isRight(), isTrue);
    verify(
      () => mockRepository.startTracking(
        eventId: 'event-1',
        initialData: initialData,
      ),
    ).called(1);
  });

  test('returns Left when repository fails', () async {
    const error = DomainException(message: 'No se pudo iniciar el tracking.');
    when(
      () => mockRepository.startTracking(
        eventId: any(named: 'eventId'),
        initialData: any(named: 'initialData'),
      ),
    ).thenAnswer((_) async => const Left(error));

    final result = await useCase(
      eventId: 'event-1',
      initialData: initialData,
    );

    expect(result, const Left(error));
  });
}
