import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/approve_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/get_event_registrations_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/get_my_registration_for_event_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/reject_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/set_registration_ready_for_edit_use_case.dart';
import 'package:rideglory/features/events/data/cache/attendees_cache.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_by_id_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/publish_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/presentation/detail/cubit/event_detail_cubit.dart';

class MockGetEventByIdUseCase extends Mock implements GetEventByIdUseCase {}

class MockGetMyRegistrationForEventUseCase extends Mock
    implements GetMyRegistrationForEventUseCase {}

class MockCancelEventRegistrationUseCase extends Mock
    implements CancelEventRegistrationUseCase {}

class MockUpdateEventUseCase extends Mock implements UpdateEventUseCase {}

class MockPublishEventUseCase extends Mock implements PublishEventUseCase {}

class MockGetEventRegistrationsUseCase extends Mock
    implements GetEventRegistrationsUseCase {}

class MockApproveRegistrationUseCase extends Mock
    implements ApproveRegistrationUseCase {}

class MockRejectRegistrationUseCase extends Mock
    implements RejectRegistrationUseCase {}

class MockSetRegistrationReadyForEditUseCase extends Mock
    implements SetRegistrationReadyForEditUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockGetEventByIdUseCase mockGetEventByIdUseCase;
  late MockGetMyRegistrationForEventUseCase mockGetMyRegistrationUseCase;
  late MockCancelEventRegistrationUseCase mockCancelRegistrationUseCase;
  late MockUpdateEventUseCase mockUpdateEventUseCase;
  late MockPublishEventUseCase mockPublishEventUseCase;
  late MockGetEventRegistrationsUseCase mockGetEventRegistrationsUseCase;
  late MockApproveRegistrationUseCase mockApproveRegistrationUseCase;
  late MockRejectRegistrationUseCase mockRejectRegistrationUseCase;
  late MockSetRegistrationReadyForEditUseCase mockSetReadyForEditUseCase;
  late MockAnalyticsService mockAnalytics;
  late EventDetailCubit cubit;

  final mockEvent = EventModel(
    id: 'evt-1',
    ownerId: 'owner-1',
    name: 'Ruta del café',
    description: 'Paseo turístico por la región cafetera',
    eventType: EventType.onRoad,
    difficulty: EventDifficulty.two,
    startDate: DateTime(2026, 6, 15),
    meetingPoint: 'Parque Berrio',
    destination: 'Santa Fe de Antioquia',
    meetingTime: DateTime(2026, 6, 15, 7, 0),
    state: EventState.scheduled,
  );

  EventDetailCubit buildCubit() {
    return EventDetailCubit(
      mockGetMyRegistrationUseCase,
      mockCancelRegistrationUseCase,
      mockGetEventByIdUseCase,
      mockUpdateEventUseCase,
      mockPublishEventUseCase,
      mockGetEventRegistrationsUseCase,
      mockApproveRegistrationUseCase,
      mockRejectRegistrationUseCase,
      mockSetReadyForEditUseCase,
      mockAnalytics,
    );
  }

  setUpAll(() {
    // EventDetailCubit.loadAttendees uses getIt<AttendeesCache>() — register
    // it once so the container is ready even though we don't call loadAttendees
    // in these tests.
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<AttendeesCache>()) {
      getIt.registerSingleton<AttendeesCache>(AttendeesCache());
    }
  });

  setUp(() {
    mockGetEventByIdUseCase = MockGetEventByIdUseCase();
    mockGetMyRegistrationUseCase = MockGetMyRegistrationForEventUseCase();
    mockCancelRegistrationUseCase = MockCancelEventRegistrationUseCase();
    mockUpdateEventUseCase = MockUpdateEventUseCase();
    mockPublishEventUseCase = MockPublishEventUseCase();
    mockGetEventRegistrationsUseCase = MockGetEventRegistrationsUseCase();
    mockApproveRegistrationUseCase = MockApproveRegistrationUseCase();
    mockRejectRegistrationUseCase = MockRejectRegistrationUseCase();
    mockSetReadyForEditUseCase = MockSetRegistrationReadyForEditUseCase();
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    cubit = buildCubit();
  });

  tearDown(() {
    cubit.close();
  });

  group('EventDetailCubit — analytics event_detail_viewed (Fase 6)', () {
    // TC-evdetail-a1: event_detail_viewed fires with correct params on success
    test(
      'TC-evdetail-a1: loadEvent success → event_detail_viewed with '
      'event_type, event_state, is_owner=0, is_read_only=0, source=deep_link',
      () async {
        when(() => mockGetEventByIdUseCase('evt-1')).thenAnswer(
          (_) async => Right(mockEvent),
        );

        await cubit.loadEvent('evt-1');

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventDetailViewed,
            {
              AnalyticsParams.eventType: EventType.onRoad.apiValue,
              AnalyticsParams.eventState: EventState.scheduled.name,
              AnalyticsParams.isOwner: 0,
              AnalyticsParams.isReadOnly: 0,
              AnalyticsParams.source: AnalyticsParams.sourceDeepLink,
            },
          ),
        ).called(1);
      },
    );

    // TC-evdetail-a2: event_type param reflects the actual event type
    test(
      'TC-evdetail-a2: loadEvent with urban event → event_detail_viewed '
      'with event_type matching urban apiValue',
      () async {
        final urbanEvent = mockEvent.copyWith(eventType: EventType.course);
        when(() => mockGetEventByIdUseCase('evt-1')).thenAnswer(
          (_) async => Right(urbanEvent),
        );

        await cubit.loadEvent('evt-1');

        final captured = verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventDetailViewed,
            captureAny(),
          ),
        ).captured;
        expect(captured, isNotEmpty);
        final params = captured.first as Map<String, Object>;
        expect(params[AnalyticsParams.eventType], EventType.course.apiValue);
      },
    );

    // TC-evdetail-a3: event_state param reflects the actual event state
    test(
      'TC-evdetail-a3: loadEvent with inProgress event → event_detail_viewed '
      'with event_state=inProgress',
      () async {
        final inProgressEvent = mockEvent.copyWith(state: EventState.inProgress);
        when(() => mockGetEventByIdUseCase('evt-1')).thenAnswer(
          (_) async => Right(inProgressEvent),
        );

        await cubit.loadEvent('evt-1');

        final captured = verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventDetailViewed,
            captureAny(),
          ),
        ).captured;
        expect(captured, isNotEmpty);
        final params = captured.first as Map<String, Object>;
        expect(params[AnalyticsParams.eventState], EventState.inProgress.name);
      },
    );

    // TC-evdetail-a4: event_detail_viewed NOT emitted on error
    test(
      'TC-evdetail-a4: loadEvent error → event_detail_viewed NOT emitted',
      () async {
        when(() => mockGetEventByIdUseCase('evt-1')).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Evento no encontrado')),
        );

        await cubit.loadEvent('evt-1');

        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventDetailViewed,
            any(),
          ),
        );
      },
    );

    // TC-evdetail-a5: event_detail_viewed fires exactly once per loadEvent call
    test(
      'TC-evdetail-a5: calling loadEvent twice → event_detail_viewed emitted '
      'exactly twice (once per call)',
      () async {
        when(() => mockGetEventByIdUseCase(any())).thenAnswer(
          (_) async => Right(mockEvent),
        );

        await cubit.loadEvent('evt-1');
        await cubit.loadEvent('evt-1');

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventDetailViewed,
            any(),
          ),
        ).called(2);
      },
    );
  });

  group('EventDetailCubit — state transitions', () {
    // TC-evdetail-1: loadEvent success emits eventResult=data
    test(
      'TC-evdetail-1: loadEvent success emits eventResult with loaded event',
      () async {
        when(() => mockGetEventByIdUseCase('evt-1')).thenAnswer(
          (_) async => Right(mockEvent),
        );

        await cubit.loadEvent('evt-1');

        final eventResult = cubit.state.eventResult;
        expect(eventResult, isA<Data<EventModel>>());
        final loaded = eventResult as Data<EventModel>;
        expect(loaded.data.id, 'evt-1');
      },
    );

    // TC-evdetail-2: loadEvent error emits eventResult=error
    test(
      'TC-evdetail-2: loadEvent error emits eventResult with DomainException',
      () async {
        when(() => mockGetEventByIdUseCase('evt-1')).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Evento no encontrado')),
        );

        await cubit.loadEvent('evt-1');

        final eventResult = cubit.state.eventResult;
        expect(eventResult, isA<Error<EventModel>>());
        final errState = eventResult as Error<EventModel>;
        expect(errState.error.message, 'Evento no encontrado');
      },
    );
  });
}
