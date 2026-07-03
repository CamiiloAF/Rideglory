// Tests for EventFormCubit.setOrganizerResponsibility (legal-consentimientos-fase5).
//
// Verifies the timestamp is recorded in state without emitting a saveResult
// change and without triggering a save/publish call to the use cases.

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/create_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/upload_event_image_use_case.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/users/domain/use_cases/get_current_user_id_use_case.dart';

class FakeEventModel extends Fake implements EventModel {}

class MockCreateEventUseCase extends Mock implements CreateEventUseCase {}

class MockUpdateEventUseCase extends Mock implements UpdateEventUseCase {}

class MockUploadEventImageUseCase extends Mock
    implements UploadEventImageUseCase {}

class MockGetCurrentUserIdUseCase extends Mock
    implements GetCurrentUserIdUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeEventModel());
  });

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
    when(() => mockGetUserId()).thenAnswer((_) async => const Right('user-1'));

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

  group('setOrganizerResponsibility', () {
    test('stores the accepted-at timestamp in state', () {
      final acceptedAt = DateTime(2026, 7, 2, 10, 30);

      cubit.setOrganizerResponsibility(acceptedAt);

      expect(cubit.state.organizerResponsibilityAcceptedAt, acceptedAt);
    });

    test('does not touch saveResult (no save/publish call)', () {
      final acceptedAt = DateTime(2026, 7, 2, 10, 30);
      final saveResultBefore = cubit.state.saveResult;

      cubit.setOrganizerResponsibility(acceptedAt);

      expect(cubit.state.saveResult, saveResultBefore);
      verifyNever(() => mockCreate(any()));
      verifyNever(() => mockUpdate(any()));
    });

    test('overwrites a previously stored timestamp', () {
      final first = DateTime(2026, 7, 1);
      final second = DateTime(2026, 7, 2);

      cubit.setOrganizerResponsibility(first);
      cubit.setOrganizerResponsibility(second);

      expect(cubit.state.organizerResponsibilityAcceptedAt, second);
    });
  });
}
