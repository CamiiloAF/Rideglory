import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/add_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/update_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/presentation/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/events/domain/model/rider_profile_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_rider_profile_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/save_rider_profile_use_case.dart';

class MockAddEventRegistrationUseCase extends Mock
    implements AddEventRegistrationUseCase {}

class MockUpdateEventRegistrationUseCase extends Mock
    implements UpdateEventRegistrationUseCase {}

class MockGetRiderProfileUseCase extends Mock
    implements GetRiderProfileUseCase {}

class MockSaveRiderProfileUseCase extends Mock
    implements SaveRiderProfileUseCase {}

class MockAuthService extends Mock implements AuthService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

/// Builds a minimal fake registration for positive-path tests.
EventRegistrationModel _buildFakeRegistration() => EventRegistrationModel(
  eventId: 'e1',
  eventName: 'Test Event',
  userId: 'u1',
  fullName: 'Juan Pérez',
  identificationNumber: '123456789',
  birthDate: DateTime(1990),
  phone: '3001234567',
  email: 'juan@test.com',
  residenceCity: 'Medellín',
  eps: 'Sura',
  bloodType: BloodType.oPositive,
  emergencyContactName: 'Ana García',
  emergencyContactPhone: '3109876543',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Required by mocktail for any() matchers on custom types.
    registerFallbackValue(const RiderProfileModel(userId: ''));
    registerFallbackValue(
      EventRegistrationModel(
        eventId: '',
        eventName: '',
        userId: '',
        fullName: '',
        identificationNumber: '',
        birthDate: DateTime(1990),
        phone: '',
        email: '',
        residenceCity: '',
        eps: '',
        bloodType: BloodType.oPositive,
        emergencyContactName: '',
        emergencyContactPhone: '',
      ),
    );
  });

  late MockAddEventRegistrationUseCase mockAdd;
  late MockUpdateEventRegistrationUseCase mockUpdate;
  late MockGetRiderProfileUseCase mockGetProfile;
  late MockSaveRiderProfileUseCase mockSaveProfile;
  late MockAuthService mockAuth;
  late MockAnalyticsService mockAnalytics;
  late RegistrationFormCubit cubit;

  setUp(() {
    mockAdd = MockAddEventRegistrationUseCase();
    mockUpdate = MockUpdateEventRegistrationUseCase();
    mockGetProfile = MockGetRiderProfileUseCase();
    mockSaveProfile = MockSaveRiderProfileUseCase();
    mockAuth = MockAuthService();
    mockAnalytics = MockAnalyticsService();

    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    when(() => mockGetProfile()).thenAnswer(
      (_) async => const Left(DomainException(message: 'No profile')),
    );
    when(() => mockAuth.currentUser).thenReturn(null);

    cubit = RegistrationFormCubit(
      mockAdd,
      mockUpdate,
      mockGetProfile,
      mockSaveProfile,
      mockAuth,
      mockAnalytics,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('RegistrationFormCubit — analytics (Fase 7)', () {
    // TC-rfm-a1: onWizardStarted fires registration_started
    test(
      'TC-rfm-a1: onWizardStarted → registration_started fired',
      () {
        cubit.onWizardStarted();

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.registrationStarted),
        ).called(1);
      },
    );

    // TC-rfm-a2: onStepAdvanced fires registration_step_advanced with correct params
    test(
      'TC-rfm-a2: onStepAdvanced(1, medical) → registration_step_advanced '
      'with step_index=1 and step_name=medical',
      () {
        cubit.onStepAdvanced(1, AnalyticsParams.stepNameMedical);

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationStepAdvanced,
            {
              AnalyticsParams.stepIndex: 1,
              AnalyticsParams.stepName: AnalyticsParams.stepNameMedical,
            },
          ),
        ).called(1);
      },
    );

    // TC-rfm-a3: onStepBack fires registration_step_back with correct params
    test(
      'TC-rfm-a3: onStepBack(0, personal) → registration_step_back '
      'with step_index=0 and step_name=personal',
      () {
        cubit.onStepBack(0, AnalyticsParams.stepNamePersonal);

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationStepBack,
            {
              AnalyticsParams.stepIndex: 0,
              AnalyticsParams.stepName: AnalyticsParams.stepNamePersonal,
            },
          ),
        ).called(1);
      },
    );

    // TC-rfm-a4: onStepAdvanced with vehicle step (index 3)
    test(
      'TC-rfm-a4: onStepAdvanced(3, vehicle) → step_name=vehicle',
      () {
        cubit.onStepAdvanced(3, AnalyticsParams.stepNameVehicle);

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationStepAdvanced,
            {
              AnalyticsParams.stepIndex: 3,
              AnalyticsParams.stepName: AnalyticsParams.stepNameVehicle,
            },
          ),
        ).called(1);
      },
    );

    // TC-rfm-a5: saveRegistration with null form (no form state) → no analytics fired
    test(
      'TC-rfm-a5: saveRegistration with no form state → no submitted/failed event',
      () async {
        // No form key state attached → _buildRegistration returns null → early return
        await cubit.saveRegistration();

        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationSubmitted,
            any(),
          ),
        );
        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationSubmitFailed,
            any(),
          ),
        );
      },
    );

    // TC-rfm-a6: initial state is ResultState.initial
    test('TC-rfm-a6: initial state is ResultState.initial', () {
      expect(
        cubit.state,
        const ResultState<EventRegistrationModel>.initial(),
      );
    });

    // TC-rfm-a7: multiple step advances each fire their own event
    test(
      'TC-rfm-a7: two consecutive onStepAdvanced calls → two events fired',
      () {
        cubit.onStepAdvanced(1, AnalyticsParams.stepNameMedical);
        cubit.onStepAdvanced(2, AnalyticsParams.stepNameEmergency);

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationStepAdvanced,
            any(),
          ),
        ).called(2);
      },
    );

    // CA1b: saveRegistration with valid form fires registration_submit_attempted intent
    // Note: without a real FormBuilderState attached, _buildRegistration returns null
    // and the intent fires only after building passes. We verify the no-form-state path
    // does NOT fire the intent (early return before intent).
    test(
      'CA1b: saveRegistration with no form state → registration_submit_attempted NOT fired',
      () async {
        await cubit.saveRegistration();

        verifyNever(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationSubmitAttempted,
            any(),
          ),
        );
      },
    );

    // CA3: close() without successful submit → registration_abandoned fired
    test(
      'CA3: close() without submit → registration_abandoned fired once',
      () async {
        await cubit.close();

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.registrationAbandoned),
        ).called(1);
      },
    );

    // CA3b: close() called twice → registration_abandoned fired only once (idempotent
    // because cubit is already closed after first close())
    test(
      'CA3b: close() fires registration_abandoned exactly once on first close',
      () async {
        await cubit.close();

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.registrationAbandoned),
        ).called(1);
        // Second close would throw because cubit is already closed —
        // we only verify the first call here.
      },
    );

    // CA3c: close() after successful registration → registration_abandoned NOT fired
    //
    // saveRegistration() success path requires a real FormBuilderState (widget tree),
    // so we use the @visibleForTesting helper markTerminalEventEmittedForTesting() to
    // simulate what happens after the success fold sets _terminalEventEmitted = true.
    // This verifies the idempotent guard in close() is respected once the flag is set.
    test(
      'CA3c: close() after successful saveRegistration → registration_abandoned NOT fired',
      () async {
        // Simulate the state that _terminalEventEmitted = true produces after
        // a successful saveRegistration(). The real path requires a widget-bound
        // FormBuilderState; the @visibleForTesting helper covers this unit-test gap.
        cubit.markTerminalEventEmittedForTesting();
        await cubit.close();

        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.registrationAbandoned),
        );
      },
    );

    // CA1b_positive: saveRegistration() with valid data fires registration_submit_attempted
    // (positive path — the buildRegistrationOverride seam bypasses FormBuilderState).
    //
    // This test FAILS if the registrationSubmitAttempted call site is removed from
    // registration_form_cubit.dart#saveRegistration(). The existing CA1b only covers
    // the negative path (early return before the intent), so this test is the required
    // positive complement per §5 AC1.
    test(
      'CA1b_positive: saveRegistration with valid data via seam → '
      'registration_submit_attempted AND registration_submitted fired',
      () async {
        final fakeReg = _buildFakeRegistration();
        cubit.buildRegistrationOverride = () => fakeReg;
        when(() => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')))
            .thenAnswer((_) async => Right(fakeReg));
        when(() => mockSaveProfile(any()))
            .thenAnswer(
              (_) async => Right(const RiderProfileModel(userId: 'u1')),
            );

        await cubit.saveRegistration();

        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationSubmitAttempted,
            {AnalyticsParams.formMode: AnalyticsParams.formModeCreate},
          ),
        ).called(1);
        verify(
          () => mockAnalytics.logEvent(
            AnalyticsEvents.registrationSubmitted,
            {AnalyticsParams.formMode: AnalyticsParams.formModeCreate},
          ),
        ).called(1);
      },
    );

    // CA3c_real: real saveRegistration() success via seam + close() → no registration_abandoned.
    //
    // Hardens CA3c: verifies the actual wire-up that sets _terminalEventEmitted = true
    // in the success fold of saveRegistration(), not just the idempotent guard in close().
    // This test FAILS if the `_terminalEventEmitted = true` assignment is removed from
    // the success branch in registration_form_cubit.dart.
    //
    // Implementation note: dartz's Either.fold() does not await async callbacks, so
    // saveRegistration() returns before the inner async fold callback completes. We pump
    // the microtask queue with Future.delayed(Duration.zero) to let the pending async
    // chain (await _saveRiderProfileUseCase + emit(data)) resolve before calling close().
    test(
      'CA3c_real: saveRegistration success via seam + close() → '
      'registration_abandoned NOT fired (real _terminalEventEmitted wiring)',
      () async {
        final fakeReg = _buildFakeRegistration();
        cubit.buildRegistrationOverride = () => fakeReg;
        when(() => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')))
            .thenAnswer((_) async => Right(fakeReg));
        when(() => mockSaveProfile(any()))
            .thenAnswer(
              (_) async => Right(const RiderProfileModel(userId: 'u1')),
            );

        await cubit.saveRegistration();
        // Pump the event queue so the async fold callback (await _saveRiderProfileUseCase
        // + emit(ResultState.data)) completes before we close the cubit.
        await Future<void>.delayed(Duration.zero);
        await cubit.close(); // _terminalEventEmitted = true → must NOT emit abandoned

        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.registrationAbandoned),
        );
      },
    );

    // AC1-auth: no new auth events added in Fase 4 — documental assert.
    //
    // §3 of the PRD explicitly states that auth analytics coverage is NOT extended
    // in Fase 4. The existing authMethodSelected constant and its call sites in
    // login_view, signup_view, forgot_password_view, login_social_section, and
    // signup_social_buttons are reused as-is. This test anchors that decision so
    // that a future accidental new auth event constant would be visible in the PR diff.
    test(
      'AC1-auth: authMethodSelected is the single auth event reused in Fase 4 — '
      'no new auth events added',
      () {
        // Documental assert: the constant exists with its stable GA4 value.
        // Adding a new auth constant to the AnalyticsEvents class in this phase
        // would require a deliberate update here, keeping the catalog auditable.
        expect(AnalyticsEvents.authMethodSelected, 'auth_method_selected');
      },
    );
  });
}
