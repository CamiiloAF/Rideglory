import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
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

/// Builds a minimal fake registration for the positive path (age guard passes,
/// [RegistrationFormCubit.buildRegistrationOverride] bypasses the widget-bound
/// FormBuilderState).
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
  shareMedicalInfo: true,
  allowOrganizerContact: true,
  riskAcceptedAt: DateTime(2026, 7, 1),
  riskAcceptanceVersion: 'v0.1-2026-06',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const RiderProfileModel(userId: ''));
    registerFallbackValue(_buildFakeRegistration());
  });

  late MockAddEventRegistrationUseCase mockAdd;
  late MockUpdateEventRegistrationUseCase mockUpdate;
  late MockGetRiderProfileUseCase mockGetProfile;
  late MockSaveRiderProfileUseCase mockSaveProfile;
  late MockAuthService mockAuth;
  late MockAnalyticsService mockAnalytics;
  late RegistrationFormCubit cubit;

  DateTime birthDateForAge(int age, {DateTime? asOf}) {
    final today = asOf ?? DateTime.now();
    return DateTime(today.year - age, today.month, today.day);
  }

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

  group('RegistrationFormCubit — age guard (waiver sheet)', () {
    test('birthDate implies age < 18 → emits local underage error, never calls '
        'the add-registration use case', () async {
      cubit.birthDateOverrideForTesting = birthDateForAge(17);

      await cubit.saveRegistration();

      expect(
        cubit.state,
        const ResultState<EventRegistrationModel>.error(
          error: DomainException(
            message: RegistrationFormCubit.underageErrorMessage,
          ),
        ),
      );
      verifyNever(
        () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
      );
    });

    test(
      'birthDate implies age exactly 18 today → passes the guard and reaches '
      'the use-case call (via buildRegistrationOverride seam)',
      () async {
        cubit.birthDateOverrideForTesting = birthDateForAge(18);
        final fakeReg = _buildFakeRegistration();
        cubit.buildRegistrationOverride = () => fakeReg;
        when(
          () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
        ).thenAnswer((_) async => Right(fakeReg));

        await cubit.saveRegistration();

        expect(cubit.state, isA<Data<EventRegistrationModel>>());
        verify(
          () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
        ).called(1);
      },
    );

    test(
      'missing birthDate (no override, no widget-bound form) → emits the '
      'local missing-birthDate error, never calls the add-registration use case',
      () async {
        await cubit.saveRegistration();

        expect(
          cubit.state,
          const ResultState<EventRegistrationModel>.error(
            error: DomainException(
              message: RegistrationFormCubit.missingBirthDateErrorMessage,
            ),
          ),
        );
        verifyNever(
          () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
        );
      },
    );

    test('built registration (via buildRegistrationOverride) carries the legal '
        'fields set by the rider (shareMedicalInfo/allowOrganizerContact/'
        'riskAcceptedAt/riskAcceptanceVersion)', () async {
      cubit.birthDateOverrideForTesting = birthDateForAge(30);
      final fakeReg = _buildFakeRegistration();
      cubit.buildRegistrationOverride = () => fakeReg;
      when(
        () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
      ).thenAnswer((invocation) async {
        final passed =
            invocation.positionalArguments.first as EventRegistrationModel;
        return Right(passed);
      });

      await cubit.saveRegistration();

      final state = cubit.state;
      expect(state, isA<Data<EventRegistrationModel>>());
      final saved = (state as Data<EventRegistrationModel>).data;
      expect(saved.shareMedicalInfo, isTrue);
      expect(saved.allowOrganizerContact, isTrue);
      expect(saved.riskAcceptedAt, isNotNull);
      expect(saved.riskAcceptanceVersion, 'v0.1-2026-06');
    });

    test('backend UNDERAGE_RIDER (422) error reaches the cubit state carrying '
        "the raw server message ('UNDERAGE_RIDER') when the local guard "
        'already passed (e.g. clock skew edge case) — the cubit itself does '
        'not rewrite/discriminate this message; per AC#7, discrimination into '
        'the underage title/message happens at the UI layer '
        '(RegistrationWaiverSheet), which detects the UNDERAGE_RIDER substring '
        'and never renders it raw — see registration_waiver_sheet_test.dart '
        "('backend UNDERAGE_RIDER error shows the dedicated underage title/"
        "message, never the raw server text')", () async {
      cubit.birthDateOverrideForTesting = birthDateForAge(30);
      final fakeReg = _buildFakeRegistration();
      cubit.buildRegistrationOverride = () => fakeReg;
      when(
        () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
      ).thenAnswer(
        (_) async => const Left(DomainException(message: 'UNDERAGE_RIDER')),
      );

      await cubit.saveRegistration();

      expect(
        cubit.state,
        const ResultState<EventRegistrationModel>.error(
          error: DomainException(message: 'UNDERAGE_RIDER'),
        ),
      );
    });
  });
}
