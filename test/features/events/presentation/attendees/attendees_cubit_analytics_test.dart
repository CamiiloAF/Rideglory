import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/approve_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/get_event_registrations_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/reject_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/set_registration_ready_for_edit_use_case.dart';
import 'package:rideglory/features/events/data/cache/attendees_cache.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';

class MockGetEventRegistrationsUseCase extends Mock
    implements GetEventRegistrationsUseCase {}

class MockApproveRegistrationUseCase extends Mock
    implements ApproveRegistrationUseCase {}

class MockRejectRegistrationUseCase extends Mock
    implements RejectRegistrationUseCase {}

class MockSetRegistrationReadyForEditUseCase extends Mock
    implements SetRegistrationReadyForEditUseCase {}

class MockAttendeesCache extends Mock implements AttendeesCache {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

final _mockRegistration = EventRegistrationModel(
  id: 'reg-1',
  eventId: 'event-1',
  eventName: 'Ruta Test',
  userId: 'user-1',
  status: RegistrationStatus.pending,
  fullName: 'Carlos García',
  identificationNumber: '123456789',
  birthDate: DateTime(1990, 5, 15),
  phone: '3001234567',
  email: 'carlos@example.com',
  residenceCity: 'Medellín',
  eps: 'Sura',
  bloodType: BloodType.oPositive,
  emergencyContactName: 'Ana García',
  emergencyContactPhone: '3009876543',
);

void main() {
  setUpAll(() {
    registerFallbackValue(RegistrationStatus.pending);
    registerFallbackValue(<String, Object>{});
  });

  late MockGetEventRegistrationsUseCase mockGetRegistrations;
  late MockApproveRegistrationUseCase mockApprove;
  late MockRejectRegistrationUseCase mockReject;
  late MockSetRegistrationReadyForEditUseCase mockReadyForEdit;
  late MockAttendeesCache mockCache;
  late MockAnalyticsService mockAnalytics;
  late AttendeesCubit cubit;

  setUp(() {
    mockGetRegistrations = MockGetEventRegistrationsUseCase();
    mockApprove = MockApproveRegistrationUseCase();
    mockReject = MockRejectRegistrationUseCase();
    mockReadyForEdit = MockSetRegistrationReadyForEditUseCase();
    mockCache = MockAttendeesCache();
    mockAnalytics = MockAnalyticsService();

    when(
      () => mockAnalytics.logEvent(any(), any<Map<String, Object>>()),
    ).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    when(() => mockCache.read(any())).thenReturn(null);
    when(() => mockCache.write(any(), any())).thenReturn(null);
    when(
      () => mockCache.updateStatus(any(), any(), any()),
    ).thenReturn(null);
    when(() => mockGetRegistrations('event-1')).thenAnswer(
      (_) async => Right([_mockRegistration]),
    );

    cubit = AttendeesCubit(
      mockGetRegistrations,
      mockApprove,
      mockReject,
      mockReadyForEdit,
      mockCache,
      mockAnalytics,
    );
  });

  tearDown(() {
    cubit.close();
  });

  Future<void> loadAttendees() async {
    await cubit.fetchAttendees('event-1');
  }

  group('AttendeesCubit — analytics (Fase 7)', () {
    // TC-att-a1: registration_approved fires on successful approve
    test(
      'TC-att-a1: approveRegistration success → registration_approved fired',
      () async {
        when(() => mockApprove.call('reg-1')).thenAnswer(
          (_) async => Right(
            _mockRegistration.copyWith(status: RegistrationStatus.approved),
          ),
        );

        await loadAttendees();
        await cubit.approveRegistration('reg-1');

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.registrationApproved),
        ).called(1);
        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationApprovalFailed,
            any(),
          ),
        );
      },
    );

    // TC-att-a2: registration_rejected fires on successful reject
    test(
      'TC-att-a2: rejectRegistration success → registration_rejected fired',
      () async {
        when(() => mockReject.call('reg-1')).thenAnswer(
          (_) async => Right(
            _mockRegistration.copyWith(status: RegistrationStatus.rejected),
          ),
        );

        await loadAttendees();
        await cubit.rejectRegistration('reg-1');

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.registrationRejected),
        ).called(1);
        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationApprovalFailed,
            any(),
          ),
        );
      },
    );

    // TC-att-a3: registration_ready_for_edit fires on successful setReadyForEdit
    test(
      'TC-att-a3: setReadyForEdit success → registration_ready_for_edit fired',
      () async {
        when(() => mockReadyForEdit.call('reg-1')).thenAnswer(
          (_) async => Right(
            _mockRegistration.copyWith(
              status: RegistrationStatus.readyForEdit,
            ),
          ),
        );

        await loadAttendees();
        await cubit.setReadyForEdit('reg-1');

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationReadyForEdit,
          ),
        ).called(1);
        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationApprovalFailed,
            any(),
          ),
        );
      },
    );

    // TC-att-a4: registration_approval_failed fires on approve failure with action param
    test(
      'TC-att-a4: approveRegistration failure → registration_approval_failed '
      'with action=approve',
      () async {
        when(() => mockApprove.call('reg-1')).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Server error')),
        );

        await loadAttendees();
        await cubit.approveRegistration('reg-1');

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationApprovalFailed,
            {AnalyticsParams.approvalAction: AnalyticsParams.approvalActionApprove},
          ),
        ).called(1);
        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationApproved,
          ),
        );
      },
    );

    // TC-att-a5: registration_approval_failed fires on reject failure with action=reject
    test(
      'TC-att-a5: rejectRegistration failure → registration_approval_failed '
      'with action=reject',
      () async {
        when(() => mockReject.call('reg-1')).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Forbidden')),
        );

        await loadAttendees();
        await cubit.rejectRegistration('reg-1');

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationApprovalFailed,
            {AnalyticsParams.approvalAction: AnalyticsParams.approvalActionReject},
          ),
        ).called(1);
        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.registrationRejected),
        );
      },
    );

    // TC-att-a6: registration_approval_failed fires on readyForEdit failure
    test(
      'TC-att-a6: setReadyForEdit failure → registration_approval_failed '
      'with action=ready_for_edit',
      () async {
        when(() => mockReadyForEdit.call('reg-1')).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Network error')),
        );

        await loadAttendees();
        await cubit.setReadyForEdit('reg-1');

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationApprovalFailed,
            {AnalyticsParams.approvalAction: AnalyticsParams.approvalActionReadyForEdit},
          ),
        ).called(1);
        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationReadyForEdit,
          ),
        );
      },
    );

    // TC-att-a7: no PII — approved event carries no registration id or rider data
    test(
      'TC-att-a7: approved event params contain no high-cardinality ids',
      () async {
        when(() => mockApprove.call('reg-1')).thenAnswer(
          (_) async => Right(
            _mockRegistration.copyWith(status: RegistrationStatus.approved),
          ),
        );

        await loadAttendees();
        await cubit.approveRegistration('reg-1');

        // registration_approved is called with NO params (no registration id, no rider uid)
        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.registrationApproved),
        ).called(1);
        // Ensure it was never called with a params map containing any id
        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationApproved,
            any(),
          ),
        );
      },
    );
  });
}
