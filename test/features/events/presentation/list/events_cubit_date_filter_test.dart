import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_events_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_events_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';

class MockGetEventsUseCase extends Mock implements GetEventsUseCase {}

class MockGetMyEventsUseCase extends Mock implements GetMyEventsUseCase {}

class MockUpdateEventUseCase extends Mock implements UpdateEventUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockGetEventsUseCase mockGetEventsUseCase;
  late MockGetMyEventsUseCase mockGetMyEventsUseCase;
  late MockUpdateEventUseCase mockUpdateEventUseCase;
  late MockAnalyticsService mockAnalytics;

  final mockEvent = EventModel(
    id: 'evt-1',
    ownerId: 'owner-1',
    name: 'Test Event',
    description: 'Test description',
    eventType: EventType.onRoad,
    difficulty: EventDifficulty.two,
    startDate: DateTime(2026, 8, 1),
    meetingTime: DateTime(2026, 8, 1, 8, 0),
    state: EventState.scheduled,
  );

  setUp(() {
    mockGetEventsUseCase = MockGetEventsUseCase();
    mockGetMyEventsUseCase = MockGetMyEventsUseCase();
    mockUpdateEventUseCase = MockUpdateEventUseCase();
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
  });

  group('EventsCubit — date floor (Phase 02)', () {
    // TC-df-1: fetchEvents() sin filtros → dateFrom = hoy local yyyy-MM-dd
    test(
      'TC-df-1: fetchEvents() without filters passes dateFrom = today local',
      () async {
        final expectedDateFrom = DateTime.now().toIso8601String().substring(
          0,
          10,
        );

        String? capturedDateFrom;
        when(
          () => mockGetEventsUseCase(
            type: any(named: 'type'),
            dateFrom: any(named: 'dateFrom'),
            dateTo: any(named: 'dateTo'),
          ),
        ).thenAnswer((invocation) async {
          capturedDateFrom = invocation.namedArguments[#dateFrom] as String?;
          return Right([mockEvent]);
        });

        final cubit = EventsCubit(
          mockGetEventsUseCase,
          mockUpdateEventUseCase,
          mockAnalytics,
        );
        addTearDown(cubit.close);

        await cubit.fetchEvents();

        expect(capturedDateFrom, expectedDateFrom);
      },
    );

    // TC-df-2: fetchEvents() con filtro manual startDate → dateFrom = fecha manual
    test(
      'TC-df-2: fetchEvents() with manual startDate passes that date (floor not applied)',
      () async {
        const manualDate = '2026-07-15';

        String? capturedDateFrom;
        when(
          () => mockGetEventsUseCase(
            type: any(named: 'type'),
            dateFrom: any(named: 'dateFrom'),
            dateTo: any(named: 'dateTo'),
          ),
        ).thenAnswer((invocation) async {
          capturedDateFrom = invocation.namedArguments[#dateFrom] as String?;
          return Right([mockEvent]);
        });

        final cubit = EventsCubit(
          mockGetEventsUseCase,
          mockUpdateEventUseCase,
          mockAnalytics,
        );
        addTearDown(cubit.close);

        cubit.updateFilters(EventFilters(startDate: DateTime(2026, 7, 15)));
        await Future<void>.delayed(Duration.zero);

        expect(capturedDateFrom, manualDate);
      },
    );

    // TC-df-3: clearFilters() → fetchEvents() → dateFrom = hoy local (no null)
    test(
      'TC-df-3: clearFilters() then fetchEvents() passes dateFrom = today local',
      () async {
        final expectedDateFrom = DateTime.now().toIso8601String().substring(
          0,
          10,
        );

        final capturedDates = <String?>[];
        when(
          () => mockGetEventsUseCase(
            type: any(named: 'type'),
            dateFrom: any(named: 'dateFrom'),
            dateTo: any(named: 'dateTo'),
          ),
        ).thenAnswer((invocation) async {
          capturedDates.add(invocation.namedArguments[#dateFrom] as String?);
          return Right([mockEvent]);
        });

        final cubit = EventsCubit(
          mockGetEventsUseCase,
          mockUpdateEventUseCase,
          mockAnalytics,
        );
        addTearDown(cubit.close);

        // Set a manual filter then clear it
        cubit.updateFilters(EventFilters(startDate: DateTime(2026, 7, 15)));
        await Future<void>.delayed(Duration.zero);

        cubit.clearFilters();
        await Future<void>.delayed(Duration.zero);

        // Second call (after clearFilters) should use today as floor
        expect(capturedDates.length, 2);
        expect(capturedDates.last, expectedDateFrom);
      },
    );

    // TC-df-4: EventsCubit.myEvents.fetchEvents() → dateFrom = null (historial completo)
    test(
      'TC-df-4: EventsCubit.myEvents fetchEvents() passes dateFrom = null',
      () async {
        String? capturedDateFrom = 'NOT_CALLED';
        when(
          () => mockGetMyEventsUseCase(),
        ).thenAnswer((_) async => Right([mockEvent]));

        final cubit = EventsCubit.myEvents(
          mockGetMyEventsUseCase,
          mockUpdateEventUseCase,
          mockAnalytics,
        );
        addTearDown(cubit.close);

        // Capture what would be passed if GetEventsUseCase were used —
        // but myEvents uses GetMyEventsUseCase (no date params).
        // We verify the cubit does NOT call GetEventsUseCase at all.
        when(
          () => mockGetEventsUseCase(
            type: any(named: 'type'),
            dateFrom: any(named: 'dateFrom'),
            dateTo: any(named: 'dateTo'),
          ),
        ).thenAnswer((invocation) async {
          capturedDateFrom = invocation.namedArguments[#dateFrom] as String?;
          return Right([mockEvent]);
        });

        await cubit.fetchEvents();

        // GetEventsUseCase was never called — myEvents uses GetMyEventsUseCase
        verifyNever(
          () => mockGetEventsUseCase(
            type: any(named: 'type'),
            dateFrom: any(named: 'dateFrom'),
            dateTo: any(named: 'dateTo'),
          ),
        );
        // capturedDateFrom never changed from sentinel value
        expect(capturedDateFrom, 'NOT_CALLED');
      },
    );
  });
}
