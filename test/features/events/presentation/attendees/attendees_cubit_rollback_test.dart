import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
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

RegistrationStatus? _currentStatus(AttendeesCubit cubit, String registrationId) {
  final state = cubit.state;
  return state.maybeWhen(
    data: (data) => data
        .firstWhere(
          (registration) => registration.id == registrationId,
          orElse: () => _mockRegistration,
        )
        .status,
    orElse: () => null,
  );
}

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
    when(() => mockCache.updateStatus(any(), any(), any())).thenReturn(null);
    when(
      () => mockGetRegistrations('event-1'),
    ).thenAnswer((_) async => Right([_mockRegistration]));

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

  group('AttendeesCubit — optimistic update + rollback', () {
    // TC-att-r1: approve reflects new status immediately (optimistic), before
    // the use case resolves.
    test(
      'TC-att-r1: approveRegistration → local status becomes approved '
      'immediately, before the use case resolves',
      () async {
        final completer = Completer<Either<DomainException, EventRegistrationModel>>();
        when(
          () => mockApprove.call('reg-1'),
        ).thenAnswer((_) => completer.future);

        await loadAttendees();
        expect(_currentStatus(cubit, 'reg-1'), RegistrationStatus.pending);

        final future = cubit.approveRegistration('reg-1');
        // Antes de resolver el use case, el estado local ya debe reflejar el
        // cambio optimista.
        expect(_currentStatus(cubit, 'reg-1'), RegistrationStatus.approved);

        completer.complete(
          Right(_mockRegistration.copyWith(status: RegistrationStatus.approved)),
        );
        await future;
      },
    );

    // TC-att-r2: approve failure rolls back to the previous status (pending).
    test(
      'TC-att-r2: approveRegistration failure → status rolls back to pending',
      () async {
        when(() => mockApprove.call('reg-1')).thenAnswer(
          (_) async => const Left(DomainException(message: 'Server error')),
        );

        await loadAttendees();
        await cubit.approveRegistration('reg-1');

        expect(_currentStatus(cubit, 'reg-1'), RegistrationStatus.pending);
      },
    );

    // TC-att-r3: approve success keeps the optimistic status (no rollback).
    test(
      'TC-att-r3: approveRegistration success → status stays approved '
      '(no rollback)',
      () async {
        when(() => mockApprove.call('reg-1')).thenAnswer(
          (_) async => Right(
            _mockRegistration.copyWith(status: RegistrationStatus.approved),
          ),
        );

        await loadAttendees();
        await cubit.approveRegistration('reg-1');

        expect(_currentStatus(cubit, 'reg-1'), RegistrationStatus.approved);
      },
    );

    // TC-att-r4: reject reflects new status immediately, before resolving.
    test(
      'TC-att-r4: rejectRegistration → local status becomes rejected '
      'immediately, before the use case resolves',
      () async {
        final completer = Completer<Either<DomainException, EventRegistrationModel>>();
        when(
          () => mockReject.call('reg-1'),
        ).thenAnswer((_) => completer.future);

        await loadAttendees();
        final future = cubit.rejectRegistration('reg-1');
        expect(_currentStatus(cubit, 'reg-1'), RegistrationStatus.rejected);

        completer.complete(
          Right(_mockRegistration.copyWith(status: RegistrationStatus.rejected)),
        );
        await future;
      },
    );

    // TC-att-r5: reject failure rolls back to the previous status (pending).
    test(
      'TC-att-r5: rejectRegistration failure → status rolls back to pending',
      () async {
        when(() => mockReject.call('reg-1')).thenAnswer(
          (_) async => const Left(DomainException(message: 'Forbidden')),
        );

        await loadAttendees();
        await cubit.rejectRegistration('reg-1');

        expect(_currentStatus(cubit, 'reg-1'), RegistrationStatus.pending);
      },
    );

    // TC-att-r6: reject success keeps the optimistic status (no rollback).
    test(
      'TC-att-r6: rejectRegistration success → status stays rejected '
      '(no rollback)',
      () async {
        when(() => mockReject.call('reg-1')).thenAnswer(
          (_) async => Right(
            _mockRegistration.copyWith(status: RegistrationStatus.rejected),
          ),
        );

        await loadAttendees();
        await cubit.rejectRegistration('reg-1');

        expect(_currentStatus(cubit, 'reg-1'), RegistrationStatus.rejected);
      },
    );

    // TC-att-r7: setReadyForEdit reflects new status immediately, before
    // resolving.
    test(
      'TC-att-r7: setReadyForEdit → local status becomes readyForEdit '
      'immediately, before the use case resolves',
      () async {
        final completer = Completer<Either<DomainException, EventRegistrationModel>>();
        when(
          () => mockReadyForEdit.call('reg-1'),
        ).thenAnswer((_) => completer.future);

        await loadAttendees();
        final future = cubit.setReadyForEdit('reg-1');
        expect(_currentStatus(cubit, 'reg-1'), RegistrationStatus.readyForEdit);

        completer.complete(
          Right(
            _mockRegistration.copyWith(status: RegistrationStatus.readyForEdit),
          ),
        );
        await future;
      },
    );

    // TC-att-r8: setReadyForEdit failure rolls back to the previous status
    // (pending).
    test(
      'TC-att-r8: setReadyForEdit failure → status rolls back to pending',
      () async {
        when(() => mockReadyForEdit.call('reg-1')).thenAnswer(
          (_) async => const Left(DomainException(message: 'Network error')),
        );

        await loadAttendees();
        await cubit.setReadyForEdit('reg-1');

        expect(_currentStatus(cubit, 'reg-1'), RegistrationStatus.pending);
      },
    );

    // TC-att-r9: setReadyForEdit success keeps the optimistic status (no
    // rollback).
    test(
      'TC-att-r9: setReadyForEdit success → status stays readyForEdit '
      '(no rollback)',
      () async {
        when(() => mockReadyForEdit.call('reg-1')).thenAnswer(
          (_) async => Right(
            _mockRegistration.copyWith(status: RegistrationStatus.readyForEdit),
          ),
        );

        await loadAttendees();
        await cubit.setReadyForEdit('reg-1');

        expect(_currentStatus(cubit, 'reg-1'), RegistrationStatus.readyForEdit);
      },
    );

    // TC-att-r10: after a rollback, a subsequent successful approve still
    // works correctly (state machine is not left corrupted).
    test(
      'TC-att-r10: rollback does not corrupt subsequent successful action',
      () async {
        when(() => mockApprove.call('reg-1')).thenAnswer(
          (_) async => const Left(DomainException(message: 'Server error')),
        );

        await loadAttendees();
        await cubit.approveRegistration('reg-1');
        expect(_currentStatus(cubit, 'reg-1'), RegistrationStatus.pending);

        when(() => mockApprove.call('reg-1')).thenAnswer(
          (_) async => Right(
            _mockRegistration.copyWith(status: RegistrationStatus.approved),
          ),
        );
        await cubit.approveRegistration('reg-1');
        expect(_currentStatus(cubit, 'reg-1'), RegistrationStatus.approved);
      },
    );
  });
}
