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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
  });
}
