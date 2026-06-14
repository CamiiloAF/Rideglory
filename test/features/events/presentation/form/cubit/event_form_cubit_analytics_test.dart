import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/create_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/upload_event_image_use_case.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/users/domain/use_cases/get_current_user_id_use_case.dart';

class MockCreateEventUseCase extends Mock implements CreateEventUseCase {}

class MockUpdateEventUseCase extends Mock implements UpdateEventUseCase {}

class MockUploadEventImageUseCase extends Mock
    implements UploadEventImageUseCase {}

class MockGetCurrentUserIdUseCase extends Mock
    implements GetCurrentUserIdUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

final _mockEvent = EventModel(
  id: 'evt-1',
  ownerId: 'owner-1',
  name: 'Ruta del café',
  description: 'Paseo turístico',
  eventType: EventType.onRoad,
  difficulty: EventDifficulty.two,
  startDate: DateTime(2026, 6, 15),
  meetingTime: DateTime(2026, 6, 15, 7),
  state: EventState.scheduled,
);

void main() {
  late MockCreateEventUseCase mockCreate;
  late MockUpdateEventUseCase mockUpdate;
  late MockUploadEventImageUseCase mockUpload;
  late MockGetCurrentUserIdUseCase mockGetUserId;
  late MockAnalyticsService mockAnalytics;
  late EventFormCubit cubit;

  setUp(() {
    mockCreate = MockCreateEventUseCase();
    mockUpdate = MockUpdateEventUseCase();
    mockUpload = MockUploadEventImageUseCase();
    mockGetUserId = MockGetCurrentUserIdUseCase();
    mockAnalytics = MockAnalyticsService();

    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});

    cubit = EventFormCubit(
      mockCreate,
      mockUpdate,
      mockUpload,
      mockGetUserId,
      mockAnalytics,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('EventFormCubit — analytics (Fase 7)', () {
    // TC-efm-a1: initialize (create mode) fires events_create_started with mode=create
    test(
      'TC-efm-a1: initialize(event: null) → events_create_started with mode=create',
      () {
        cubit.initialize();

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsCreateStarted,
            {AnalyticsParams.formMode: AnalyticsParams.formModeCreate},
          ),
        ).called(1);
      },
    );

    // TC-efm-a2: initialize (edit mode) fires events_create_started with mode=edit
    test(
      'TC-efm-a2: initialize(event: mockEvent) → events_create_started with mode=edit',
      () {
        cubit.initialize(event: _mockEvent);

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsCreateStarted,
            {AnalyticsParams.formMode: AnalyticsParams.formModeEdit},
          ),
        ).called(1);
      },
    );

    // TC-efm-a3: saveEvent success (create) → events_published with mode=create
    test(
      'TC-efm-a3: saveEvent success in create mode → events_published with mode=create',
      () async {
        when(() => mockCreate(_mockEvent)).thenAnswer(
          (_) async => Right(_mockEvent),
        );

        cubit.initialize(); // sets isEditing = false
        await cubit.saveEvent(_mockEvent);

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsPublished,
            {AnalyticsParams.formMode: AnalyticsParams.formModeCreate},
          ),
        ).called(1);
        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsPublishFailed,
            any(),
          ),
        );
      },
    );

    // TC-efm-a4: saveEvent success (edit) → events_published with mode=edit
    test(
      'TC-efm-a4: saveEvent success in edit mode → events_published with mode=edit',
      () async {
        when(() => mockUpdate(_mockEvent)).thenAnswer(
          (_) async => Right(_mockEvent),
        );

        cubit.initialize(event: _mockEvent); // sets isEditing = true
        await cubit.saveEvent(_mockEvent);

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsPublished,
            {AnalyticsParams.formMode: AnalyticsParams.formModeEdit},
          ),
        ).called(1);
      },
    );

    // TC-efm-a5: saveEvent failure → events_publish_failed with categorized reason
    test(
      'TC-efm-a5: saveEvent failure → events_publish_failed with failure_category',
      () async {
        when(() => mockCreate(_mockEvent)).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'network timeout')),
        );

        cubit.initialize();
        await cubit.saveEvent(_mockEvent);

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsPublishFailed,
            {
              AnalyticsParams.formMode: AnalyticsParams.formModeCreate,
              AnalyticsParams.failureCategory:
                  AnalyticsParams.failureCategoryNetwork,
            },
          ),
        ).called(1);
        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsPublished,
            any(),
          ),
        );
      },
    );

    // TC-efm-a6: saveEvent generic failure → failure_category=unknown
    test(
      'TC-efm-a6: saveEvent generic failure → failure_category=unknown',
      () async {
        when(() => mockCreate(_mockEvent)).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Something went wrong')),
        );

        cubit.initialize();
        await cubit.saveEvent(_mockEvent);

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsPublishFailed,
            {
              AnalyticsParams.formMode: AnalyticsParams.formModeCreate,
              AnalyticsParams.failureCategory:
                  AnalyticsParams.failureCategoryUnknown,
            },
          ),
        ).called(1);
      },
    );

    // TC-efm-a7: state transitions — initial state is EventFormState
    test('TC-efm-a7: initial state is EventFormState with initial saveResult', () {
      expect(cubit.state.saveResult, const ResultState<EventModel>.initial());
    });

    // TC-efm-a8: saveEvent success emits data state
    test('TC-efm-a8: saveEvent success → state.saveResult is Data', () async {
      when(() => mockCreate(_mockEvent)).thenAnswer(
        (_) async => Right(_mockEvent),
      );

      cubit.initialize();
      await cubit.saveEvent(_mockEvent);

      expect(cubit.state.saveResult, isA<Data<EventModel>>());
    });

    // TC-efm-a9: saveEvent failure → state.saveResult is Error
    test('TC-efm-a9: saveEvent failure → state.saveResult is Error', () async {
      when(() => mockCreate(_mockEvent)).thenAnswer(
        (_) async => const Left(DomainException(message: 'Error')),
      );

      cubit.initialize();
      await cubit.saveEvent(_mockEvent);

      expect(cubit.state.saveResult, isA<Error<EventModel>>());
    });

    // CA1: saveEvent fires events_publish_attempted intent before async work
    test(
      'CA1: saveEvent → events_publish_attempted with form_mode fired first',
      () async {
        when(() => mockCreate(_mockEvent)).thenAnswer(
          (_) async => Right(_mockEvent),
        );

        cubit.initialize();
        await cubit.saveEvent(_mockEvent);

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsPublishAttempted,
            {AnalyticsParams.formMode: AnalyticsParams.formModeCreate},
          ),
        ).called(1);
      },
    );

    // CA2a: nextStep fires events_step_advanced with correct step_index and step_name
    test(
      'CA2a: nextStep from step 0 → events_step_advanced step_index=1 step_name=config',
      () {
        cubit.initialize();
        cubit.nextStep();

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsStepAdvanced,
            {
              AnalyticsParams.stepIndex: 1,
              AnalyticsParams.stepName: 'config',
            },
          ),
        ).called(1);
      },
    );

    // CA2b: prevStep fires events_step_back with correct step_index and step_name
    test(
      'CA2b: prevStep from step 1 → events_step_back step_index=0 step_name=basics',
      () {
        cubit.initialize();
        cubit.nextStep(); // go to step 1
        cubit.prevStep(); // back to step 0

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsStepBack,
            {
              AnalyticsParams.stepIndex: 0,
              AnalyticsParams.stepName: 'basics',
            },
          ),
        ).called(1);
      },
    );

    // CA2c: close() without publish → events_create_abandoned with abandonedAtStep
    test(
      'CA2c: close() without publish → events_create_abandoned fired once',
      () async {
        cubit.initialize();
        cubit.nextStep(); // step 1
        await cubit.close();

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsCreateAbandoned,
            {
              AnalyticsParams.formMode: AnalyticsParams.formModeCreate,
              AnalyticsParams.abandonedAtStep: 1,
            },
          ),
        ).called(1);
      },
    );

    // CA2d: close() after successful publish → events_create_abandoned NOT fired (idempotent)
    test(
      'CA2d: close() after saveEvent success → events_create_abandoned NOT fired',
      () async {
        when(() => mockCreate(_mockEvent)).thenAnswer(
          (_) async => Right(_mockEvent),
        );

        cubit.initialize();
        await cubit.saveEvent(_mockEvent);
        await cubit.close();

        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsCreateAbandoned,
            any(),
          ),
        );
      },
    );

    // CA2e: nextStep beyond step 3 does not fire events_step_advanced
    test(
      'CA2e: nextStep when already at step 3 → events_step_advanced NOT fired',
      () {
        cubit.initialize();
        cubit.goToStep(3);
        cubit.nextStep(); // should be a no-op

        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsStepAdvanced,
            any(),
          ),
        );
      },
    );

    // CA2f: prevStep when at step 0 does not fire events_step_back
    test(
      'CA2f: prevStep when already at step 0 → events_step_back NOT fired',
      () {
        cubit.initialize();
        cubit.prevStep(); // should be a no-op

        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.eventsStepBack, any()),
        );
      },
    );
  });
}
