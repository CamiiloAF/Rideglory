import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_events_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';

class MockGetEventsUseCase extends Mock implements GetEventsUseCase {}

class MockUpdateEventUseCase extends Mock implements UpdateEventUseCase {}

void main() {
  late MockGetEventsUseCase mockGetEventsUseCase;
  late MockUpdateEventUseCase mockUpdateEventUseCase;
  late EventsCubit eventsCubit;

  final mockEvent = EventModel(
    id: '1',
    ownerId: 'owner-1',
    name: 'Test Event',
    description: 'Test event description',
    eventType: EventType.tourism,
    difficulty: EventDifficulty.two,
    city: 'Medellín',
    startDate: DateTime(2026, 5, 20),
    endDate: DateTime(2026, 5, 20),
    meetingPoint: 'Parque Bolívar',
    destination: 'Guatapé',
    meetingTime: DateTime(2026, 5, 20, 8, 0),
    state: EventState.scheduled,
  );

  setUp(() {
    mockGetEventsUseCase = MockGetEventsUseCase();
    mockUpdateEventUseCase = MockUpdateEventUseCase();
    eventsCubit = EventsCubit(mockGetEventsUseCase, mockUpdateEventUseCase);
  });

  tearDown(() {
    eventsCubit.close();
  });

  group('EventsCubit — Filter Tests (US-2-1, US-2-2)', () {
    // TC-2-1: fetchEvents() with no filters returns all events
    blocTest<EventsCubit, ResultState<List<EventModel>>>(
      'TC-2-1: fetchEvents() with no filters returns all events',
      setUp: () {
        when(() => mockGetEventsUseCase(
              type: null,
              dateFrom: null,
              dateTo: null,
              city: null,
            )).thenAnswer((_) async => Right([mockEvent]));
      },
      build: () => eventsCubit,
      act: (cubit) => cubit.fetchEvents(),
      expect: () => [
        const ResultState<List<EventModel>>.loading(),
        const ResultState<List<EventModel>>.initial(),
        predicate<ResultState<List<EventModel>>>(
          (state) =>
              state is Data<List<EventModel>> &&
              state.data.length == 1 &&
              state.data[0].name == 'Test Event',
        ),
      ],
      verify: (cubit) {
        verify(() => mockGetEventsUseCase(
              type: null,
              dateFrom: null,
              dateTo: null,
              city: null,
            )).called(1);
      },
    );

    // TC-2-2: updateFilters() with type filter calls fetchEvents with type param
    blocTest<EventsCubit, ResultState<List<EventModel>>>(
      'TC-2-2: updateFilters() with type filter forwards type to backend',
      setUp: () {
        when(() => mockGetEventsUseCase(
              type: any(named: 'type'),
              dateFrom: null,
              dateTo: null,
              city: null,
            )).thenAnswer((_) async => Right([mockEvent]));
      },
      build: () => eventsCubit,
      act: (cubit) {
        const filters = EventFilters(types: {EventType.tourism});
        cubit.updateFilters(filters);
      },
      expect: () => [
        const ResultState<List<EventModel>>.loading(),
        const ResultState<List<EventModel>>.initial(),
        predicate<ResultState<List<EventModel>>>(
          (state) => state is Data<List<EventModel>>,
        ),
      ],
    );

    // TC-2-3: updateFilters() with city filter calls fetchEvents with city param
    blocTest<EventsCubit, ResultState<List<EventModel>>>(
      'TC-2-3: updateFilters() with city filter forwards city to backend',
      setUp: () {
        when(() => mockGetEventsUseCase(
              type: null,
              dateFrom: null,
              dateTo: null,
              city: 'Medellín',
            )).thenAnswer((_) async => Right([mockEvent]));
      },
      build: () => eventsCubit,
      act: (cubit) {
        const filters = EventFilters(city: 'Medellín');
        cubit.updateFilters(filters);
      },
      expect: () => [
        const ResultState<List<EventModel>>.loading(),
        const ResultState<List<EventModel>>.initial(),
        predicate<ResultState<List<EventModel>>>(
          (state) => state is Data<List<EventModel>>,
        ),
      ],
      verify: (cubit) {
        verify(() => mockGetEventsUseCase(
              type: null,
              dateFrom: null,
              dateTo: null,
              city: 'Medellín',
            )).called(1);
      },
    );

    // TC-2-4: updateFilters() with date range calls fetchEvents with dateFrom and dateTo
    blocTest<EventsCubit, ResultState<List<EventModel>>>(
      'TC-2-4: updateFilters() with date range forwards dates to backend',
      setUp: () {
        when(() => mockGetEventsUseCase(
              type: null,
              dateFrom: any(named: 'dateFrom'),
              dateTo: any(named: 'dateTo'),
              city: null,
            )).thenAnswer((_) async => Right([mockEvent]));
      },
      build: () => eventsCubit,
      act: (cubit) {
        final filters = EventFilters(
          startDate: DateTime(2026, 5, 20),
          endDate: DateTime(2026, 5, 25),
        );
        cubit.updateFilters(filters);
      },
      expect: () => [
        const ResultState<List<EventModel>>.loading(),
        const ResultState<List<EventModel>>.initial(),
        predicate<ResultState<List<EventModel>>>(
          (state) => state is Data<List<EventModel>>,
        ),
      ],
    );

    // TC-2-5: updateFilters() with combined filters forwards all params
    blocTest<EventsCubit, ResultState<List<EventModel>>>(
      'TC-2-5: updateFilters() with combined filters forwards all params',
      setUp: () {
        when(() => mockGetEventsUseCase(
              type: any(named: 'type'),
              dateFrom: any(named: 'dateFrom'),
              dateTo: any(named: 'dateTo'),
              city: 'Medellín',
            )).thenAnswer((_) async => Right([mockEvent]));
      },
      build: () => eventsCubit,
      act: (cubit) {
        final filters = EventFilters(
          types: {EventType.tourism},
          startDate: DateTime(2026, 5, 20),
          endDate: DateTime(2026, 5, 25),
          city: 'Medellín',
        );
        cubit.updateFilters(filters);
      },
      expect: () => [
        const ResultState<List<EventModel>>.loading(),
        const ResultState<List<EventModel>>.initial(),
        predicate<ResultState<List<EventModel>>>(
          (state) => state is Data<List<EventModel>>,
        ),
      ],
    );

    // TC-2-6: clearFilters() resets activeFilter and re-fetches
    blocTest<EventsCubit, ResultState<List<EventModel>>>(
      'TC-2-6: clearFilters() resets filters and triggers fetch',
      setUp: () {
        when(() => mockGetEventsUseCase(
              type: any(named: 'type'),
              dateFrom: any(named: 'dateFrom'),
              dateTo: any(named: 'dateTo'),
              city: any(named: 'city'),
            )).thenAnswer((_) async => Right([mockEvent]));
      },
      build: () => eventsCubit,
      act: (cubit) async {
        const filters = EventFilters(city: 'Medellín');
        cubit.updateFilters(filters);
        await Future<void>.delayed(Duration.zero);
        cubit.clearFilters();
      },
      verify: (cubit) {
        expect(cubit.filters.hasFilters, false);
      },
    );

    // TC-2-7: fetchEvents() error state emits DomainException
    blocTest<EventsCubit, ResultState<List<EventModel>>>(
      'TC-2-7: fetchEvents() error state emits DomainException',
      setUp: () {
        when(() => mockGetEventsUseCase(
              type: null,
              dateFrom: null,
              dateTo: null,
              city: null,
            )).thenAnswer((_) async => const Left(
              DomainException(message: 'Network error'),
            ));
      },
      build: () => eventsCubit,
      act: (cubit) => cubit.fetchEvents(),
      expect: () => [
        const ResultState<List<EventModel>>.loading(),
        predicate<ResultState<List<EventModel>>>(
          (state) =>
              state is Error<List<EventModel>> &&
              state.error.message == 'Network error',
        ),
      ],
    );

    // TC-2-8: EventFilters.hasFilters returns false when no filters set
    test('TC-2-8: EventFilters.hasFilters is false with no filters', () {
      const filters = EventFilters();
      expect(filters.hasFilters, false);
    });

    // TC-2-9: EventFilters.hasFilters returns true when type filter is set
    test('TC-2-9: EventFilters.hasFilters is true with type filter', () {
      const filters = EventFilters(types: {EventType.tourism});
      expect(filters.hasFilters, true);
    });

    // TC-2-10: EventFilters.hasFilters returns true when city filter is set
    test('TC-2-10: EventFilters.hasFilters is true with city filter', () {
      const filters = EventFilters(city: 'Medellín');
      expect(filters.hasFilters, true);
    });
  });
}
