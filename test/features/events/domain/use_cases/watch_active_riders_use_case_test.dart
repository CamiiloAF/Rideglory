import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/domain/repository/tracking_repository.dart';
import 'package:rideglory/features/events/domain/use_cases/watch_active_riders_use_case.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

void main() {
  late MockTrackingRepository mockRepository;
  late WatchActiveRidersUseCase useCase;

  final rider = RiderTrackingModel(
    userId: 'user-1',
    fullName: 'Camilo Agudelo',
    role: RiderTrackingRole.rider,
    latitude: 4.65,
    longitude: -74.05,
    speedKmh: 20,
    distanceMeters: 500,
    batteryPercent: 90,
    isActive: true,
    deviceLabel: 'iPhone',
    lastUpdated: DateTime(2026, 8, 1),
  );

  setUp(() {
    mockRepository = MockTrackingRepository();
    useCase = WatchActiveRidersUseCase(mockRepository);
  });

  test('delegates to repository.watchActiveRiders and forwards emitted riders', () async {
    when(
      () => mockRepository.watchActiveRiders('event-1'),
    ).thenAnswer((_) => Stream.value([rider]));

    final result = await useCase('event-1').first;

    expect(result, [rider]);
    verify(() => mockRepository.watchActiveRiders('event-1')).called(1);
  });

  test('forwards stream errors from the repository', () async {
    when(
      () => mockRepository.watchActiveRiders('event-1'),
    ).thenAnswer(
      (_) => Stream<List<RiderTrackingModel>>.error(StateError('ws down')),
    );

    await expectLater(
      useCase('event-1'),
      emitsError(isA<StateError>()),
    );
  });
}
