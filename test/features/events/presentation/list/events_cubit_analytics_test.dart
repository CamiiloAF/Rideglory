import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
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
    eventType: EventType.tourism,
    difficulty: EventDifficulty.two,
    city: 'Medellín',
    startDate: DateTime(2026, 6, 20),
    meetingPoint: 'Parque Bolívar',
    destination: 'Guatapé',
    meetingTime: DateTime(2026, 6, 20, 8, 0),
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

  group('EventsCubit — analytics events_list_viewed (Fase 6)', () {
    // TC-evlist-a1: events_list_viewed fires with list_scope=all on success
    test(
      'TC-evlist-a1: fetchEvents() success → events_list_viewed with '
      'result_count and list_scope=all',
      () async {
        when(
          () => mockGetEventsUseCase(
            type: null,
            dateFrom: null,
            dateTo: null,
            city: null,
          ),
        ).thenAnswer((_) async => Right([mockEvent, mockEvent]));

        final cubit = EventsCubit(
          mockGetEventsUseCase,
          mockUpdateEventUseCase,
          mockAnalytics,
        );
        addTearDown(cubit.close);

        await cubit.fetchEvents();

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsListViewed,
            {
              AnalyticsParams.resultCount: 2,
              AnalyticsParams.listScope: AnalyticsParams.listScopeAll,
            },
          ),
        ).called(1);
      },
    );

    // TC-evlist-a2: events_list_viewed fires with list_scope=mine for myEvents cubit
    test(
      'TC-evlist-a2: EventsCubit.myEvents fetchEvents() success → '
      'events_list_viewed with list_scope=mine',
      () async {
        when(() => mockGetMyEventsUseCase()).thenAnswer(
          (_) async => Right([mockEvent]),
        );

        final cubit = EventsCubit.myEvents(
          mockGetMyEventsUseCase,
          mockUpdateEventUseCase,
          mockAnalytics,
        );
        addTearDown(cubit.close);

        await cubit.fetchEvents();

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsListViewed,
            {
              AnalyticsParams.resultCount: 1,
              AnalyticsParams.listScope: AnalyticsParams.listScopeMine,
            },
          ),
        ).called(1);
      },
    );

    // TC-evlist-a3: result_count reflects filtered count, not total backend count
    test(
      'TC-evlist-a3: fetchEvents() with type filter → events_list_viewed '
      'result_count equals filtered list length',
      () async {
        final otherEvent = EventModel(
          id: 'evt-2',
          ownerId: 'owner-1',
          name: 'Urban Event',
          description: 'Rodada urbana',
          eventType: EventType.urban,
          difficulty: EventDifficulty.one,
          city: 'Bogotá',
          startDate: DateTime(2026, 6, 22),
          meetingPoint: 'Plaza Bolívar',
          destination: 'Usaquén',
          meetingTime: DateTime(2026, 6, 22, 9, 0),
          state: EventState.scheduled,
        );

        // Backend returns both, but local filter will keep only tourism
        when(
          () => mockGetEventsUseCase(
            type: EventType.tourism.apiValue,
            dateFrom: null,
            dateTo: null,
            city: null,
          ),
        ).thenAnswer((_) async => Right([mockEvent, otherEvent]));

        final cubit = EventsCubit(
          mockGetEventsUseCase,
          mockUpdateEventUseCase,
          mockAnalytics,
        );
        addTearDown(cubit.close);

        cubit.updateFilters(const EventFilters(types: {EventType.tourism}));
        // updateFilters calls fetchEvents internally — wait for it
        await Future<void>.delayed(Duration.zero);

        // After local filter, only 1 tourism event should remain
        final captured = verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsListViewed,
            captureAny(),
          ),
        ).captured;
        expect(captured, isNotEmpty);
        final params = captured.last as Map<String, Object>;
        expect(params[AnalyticsParams.listScope], AnalyticsParams.listScopeAll);
        // result_count is the filtered count (1 tourism out of 2 events)
        expect(params[AnalyticsParams.resultCount], 1);
      },
    );

    // TC-evlist-a4: events_list_viewed NOT emitted on error
    test(
      'TC-evlist-a4: fetchEvents() error → events_list_viewed NOT emitted',
      () async {
        when(
          () => mockGetEventsUseCase(
            type: null,
            dateFrom: null,
            dateTo: null,
            city: null,
          ),
        ).thenAnswer(
          (_) async => const Left(DomainException(message: 'Network error')),
        );

        final cubit = EventsCubit(
          mockGetEventsUseCase,
          mockUpdateEventUseCase,
          mockAnalytics,
        );
        addTearDown(cubit.close);

        await cubit.fetchEvents();

        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsListViewed,
            any(),
          ),
        );
      },
    );

    // TC-evlist-a5: events_list_viewed NOT emitted on local mutations (updateSearchQuery)
    test(
      'TC-evlist-a5: updateSearchQuery() does NOT emit events_list_viewed '
      '(only real fetch triggers it)',
      () async {
        when(
          () => mockGetEventsUseCase(
            type: null,
            dateFrom: null,
            dateTo: null,
            city: null,
          ),
        ).thenAnswer((_) async => Right([mockEvent]));

        final cubit = EventsCubit(
          mockGetEventsUseCase,
          mockUpdateEventUseCase,
          mockAnalytics,
        );
        addTearDown(cubit.close);

        // First real fetch
        await cubit.fetchEvents();
        clearInteractions(mockAnalytics);

        // Local search mutation — must NOT fire the analytics event
        cubit.updateSearchQuery('test');

        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsListViewed,
            any(),
          ),
        );
      },
    );

    // TC-evlist-a6: events_list_viewed NOT emitted on local addEvent/updateEvent/removeEvent
    test(
      'TC-evlist-a6: local mutations (addEvent, updateEvent, removeEvent) '
      'do NOT emit events_list_viewed',
      () async {
        when(
          () => mockGetEventsUseCase(
            type: null,
            dateFrom: null,
            dateTo: null,
            city: null,
          ),
        ).thenAnswer((_) async => Right([mockEvent]));

        final cubit = EventsCubit(
          mockGetEventsUseCase,
          mockUpdateEventUseCase,
          mockAnalytics,
        );
        addTearDown(cubit.close);

        await cubit.fetchEvents();
        clearInteractions(mockAnalytics);

        cubit.addEvent(mockEvent.copyWith(id: 'evt-new'));
        cubit.updateEvent(mockEvent.copyWith(name: 'Updated'));
        cubit.removeEvent('evt-1');

        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsListViewed,
            any(),
          ),
        );
      },
    );
  });
}
