import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/home/domain/models/home_data.dart';
import 'package:rideglory/features/home/domain/use_cases/get_home_data_use_case.dart';
import 'package:rideglory/features/home/presentation/cubit/home_cubit.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class MockGetHomeDataUseCase extends Mock implements GetHomeDataUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockGetHomeDataUseCase mockGetHomeDataUseCase;
  late MockAnalyticsService mockAnalytics;
  late HomeCubit homeCubit;

  final mockEvent = EventModel(
    id: 'evt-1',
    ownerId: 'owner-1',
    name: 'Ruta del café',
    description: 'Paseo turístico',
    eventType: EventType.onRoad,
    difficulty: EventDifficulty.two,
    startDate: DateTime(2026, 6, 15),
    meetingTime: DateTime(2026, 6, 15, 7, 0),
    state: EventState.scheduled,
  );

  const mockVehicle = VehicleModel(
    id: 'v-1',
    name: 'BMW R1250GS',
    currentMileage: 12000,
    isMainVehicle: true,
  );

  setUp(() {
    mockGetHomeDataUseCase = MockGetHomeDataUseCase();
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    homeCubit = HomeCubit(mockGetHomeDataUseCase, mockAnalytics);
  });

  tearDown(() {
    homeCubit.close();
  });

  group('HomeCubit — analytics (Fase 6)', () {
    // TC-home-a1: home_viewed fires with correct params on successful load
    test(
      'TC-home-a1: loadHomeData success → home_viewed with upcomingEventsCount '
      'and hasMainVehicle=1',
      () async {
        when(() => mockGetHomeDataUseCase()).thenAnswer(
          (_) async => Right(
            HomeData(mainVehicle: mockVehicle, upcomingEvents: [mockEvent]),
          ),
        );

        await homeCubit.loadHomeData();

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.homeViewed, {
            AnalyticsParams.upcomingEventsCount: 1,
            AnalyticsParams.hasMainVehicle: 1,
          }),
        ).called(1);
      },
    );

    // TC-home-a2: home_viewed fires with hasMainVehicle=0 when no main vehicle
    test('TC-home-a2: loadHomeData success with no main vehicle → '
        'home_viewed with hasMainVehicle=0', () async {
      when(() => mockGetHomeDataUseCase()).thenAnswer(
        (_) async => Right(
          HomeData(mainVehicle: null, upcomingEvents: [mockEvent, mockEvent]),
        ),
      );

      await homeCubit.loadHomeData();

      verify(
        () => mockAnalytics.logEvent(AnalyticsEvents.homeViewed, {
          AnalyticsParams.upcomingEventsCount: 2,
          AnalyticsParams.hasMainVehicle: 0,
        }),
      ).called(1);
    });

    // TC-home-a3: home_viewed fires with upcomingEventsCount=0 when list empty
    test('TC-home-a3: loadHomeData success with empty event list → '
        'home_viewed with upcomingEventsCount=0', () async {
      when(() => mockGetHomeDataUseCase()).thenAnswer(
        (_) async =>
            const Right(HomeData(mainVehicle: mockVehicle, upcomingEvents: [])),
      );

      await homeCubit.loadHomeData();

      verify(
        () => mockAnalytics.logEvent(AnalyticsEvents.homeViewed, {
          AnalyticsParams.upcomingEventsCount: 0,
          AnalyticsParams.hasMainVehicle: 1,
        }),
      ).called(1);
    });

    // TC-home-a4: home_viewed must NOT fire on error
    test('TC-home-a4: loadHomeData error → home_viewed NOT emitted', () async {
      when(() => mockGetHomeDataUseCase()).thenAnswer(
        (_) async => const Left(DomainException(message: 'Server error')),
      );

      await homeCubit.loadHomeData();

      verifyNever(
        () => mockAnalytics.logEvent(AnalyticsEvents.homeViewed, any()),
      );
    });
  });

  group('HomeCubit — state transitions', () {
    // TC-home-1: initial state is HomeInitial
    test('TC-home-1: initial state is HomeInitial', () {
      expect(homeCubit.state, isA<HomeInitial>());
    });

    // TC-home-2: success path emits HomeLoading then HomeLoaded
    blocTest<HomeCubit, HomeState>(
      'TC-home-2: loadHomeData success emits HomeLoading then HomeLoaded',
      setUp: () {
        when(() => mockGetHomeDataUseCase()).thenAnswer(
          (_) async => Right(
            HomeData(mainVehicle: mockVehicle, upcomingEvents: [mockEvent]),
          ),
        );
      },
      build: () => homeCubit,
      act: (cubit) => cubit.loadHomeData(),
      expect: () => [
        isA<HomeLoading>(),
        predicate<HomeState>(
          (state) => state is HomeLoaded && state.upcomingEvents.length == 1,
        ),
      ],
    );

    // TC-home-3: error path emits HomeLoading then HomeError
    blocTest<HomeCubit, HomeState>(
      'TC-home-3: loadHomeData error emits HomeLoading then HomeError',
      setUp: () {
        when(() => mockGetHomeDataUseCase()).thenAnswer(
          (_) async => const Left(DomainException(message: 'Error de red')),
        );
      },
      build: () => homeCubit,
      act: (cubit) => cubit.loadHomeData(),
      expect: () => [
        isA<HomeLoading>(),
        predicate<HomeState>(
          (state) => state is HomeError && state.message == 'Error de red',
        ),
      ],
    );
  });
}
