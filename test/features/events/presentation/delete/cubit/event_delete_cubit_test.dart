import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/events/domain/use_cases/delete_event_use_case.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';

class MockDeleteEventUseCase extends Mock implements DeleteEventUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockDeleteEventUseCase mockDeleteEventUseCase;
  late MockAnalyticsService mockAnalytics;
  late EventDeleteCubit cubit;

  setUp(() {
    mockDeleteEventUseCase = MockDeleteEventUseCase();
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    cubit = EventDeleteCubit(mockDeleteEventUseCase, mockAnalytics);
  });

  tearDown(() {
    cubit.close();
  });

  group('EventDeleteCubit — analytics (Fase 7)', () {
    // TC-del-a1: events_delete_attempted fires before the use case resolves
    test(
      'TC-del-a1: deleteEvent → events_delete_attempted fires immediately',
      () async {
        when(() => mockDeleteEventUseCase('evt-1')).thenAnswer(
          (_) async => const Right(Nothing()),
        );

        await cubit.deleteEvent('evt-1');

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.eventsDeleteAttempted),
        ).called(1);
      },
    );

    // TC-del-a2: events_delete_succeeded fires on success
    test(
      'TC-del-a2: deleteEvent success → events_delete_succeeded fired',
      () async {
        when(() => mockDeleteEventUseCase('evt-1')).thenAnswer(
          (_) async => const Right(Nothing()),
        );

        await cubit.deleteEvent('evt-1');

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.eventsDeleteSucceeded),
        ).called(1);
        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsDeleteFailed,
            any(),
          ),
        );
      },
    );

    // TC-del-a3: events_delete_failed fires on failure with categorized reason
    test(
      'TC-del-a3: deleteEvent failure → events_delete_failed fired with failure_category',
      () async {
        when(() => mockDeleteEventUseCase('evt-1')).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'network timeout')),
        );

        await cubit.deleteEvent('evt-1');

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsDeleteFailed,
            {AnalyticsParams.failureCategory: AnalyticsParams.failureCategoryNetwork},
          ),
        ).called(1);
        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsDeleteSucceeded,
          ),
        );
      },
    );

    // TC-del-a4: events_delete_failed failure_category is unknown for generic errors
    test(
      'TC-del-a4: deleteEvent generic error → failure_category == unknown',
      () async {
        when(() => mockDeleteEventUseCase('evt-1')).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Something went wrong')),
        );

        await cubit.deleteEvent('evt-1');

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.eventsDeleteFailed,
            {AnalyticsParams.failureCategory: AnalyticsParams.failureCategoryUnknown},
          ),
        ).called(1);
      },
    );
  });

  group('EventDeleteCubit — state transitions', () {
    // TC-del-1: initial state is ResultState.initial
    test('TC-del-1: initial state is ResultState.initial', () {
      expect(cubit.state, const ResultState<String>.initial());
    });

    // TC-del-2: success emits loading then data
    blocTest<EventDeleteCubit, ResultState<String>>(
      'TC-del-2: deleteEvent success emits loading then data',
      setUp: () {
        when(() => mockDeleteEventUseCase('evt-1')).thenAnswer(
          (_) async => const Right(Nothing()),
        );
      },
      build: () => cubit,
      act: (c) => c.deleteEvent('evt-1'),
      expect: () => [isA<Loading<String>>(), isA<Data<String>>()],
    );

    // TC-del-3: failure emits loading then error
    blocTest<EventDeleteCubit, ResultState<String>>(
      'TC-del-3: deleteEvent failure emits loading then error',
      setUp: () {
        when(() => mockDeleteEventUseCase('evt-1')).thenAnswer(
          (_) async => const Left(DomainException(message: 'Error')),
        );
      },
      build: () => cubit,
      act: (c) => c.deleteEvent('evt-1'),
      expect: () => [isA<Loading<String>>(), isA<Error<String>>()],
    );
  });
}
