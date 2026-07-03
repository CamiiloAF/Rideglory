import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';
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

EventRegistrationModel _existingRegistration(
  BloodType bloodType, {
  bool shareMedicalInfo = false,
  bool allowOrganizerContact = false,
}) => EventRegistrationModel(
  id: 'reg-1',
  eventId: 'event-1',
  eventName: 'Rodada Test',
  userId: 'user-1',
  fullName: 'Rider Test',
  identificationNumber: '123456',
  birthDate: DateTime(2000, 1, 1),
  phone: '3001234567',
  email: 'rider@test.com',
  residenceCity: 'Bogotá',
  eps: 'Sura',
  bloodType: bloodType,
  shareMedicalInfo: shareMedicalInfo,
  allowOrganizerContact: allowOrganizerContact,
  emergencyContactName: 'Contact Test',
  emergencyContactPhone: '3007654321',
);

/// Minimal FormBuilder standing in for the real wizard, wired with the exact
/// [RegistrationFormFields] names required by
/// [RegistrationFormCubit]._buildRegistration so we can exercise the real
/// preload -> save flow without pumping the full production wizard widget
/// tree (event data, focus chain, l10n-heavy steps).
class _MinimalRegistrationForm extends StatelessWidget {
  const _MinimalRegistrationForm({required this.cubit});

  final RegistrationFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FormBuilder(
          key: cubit.formKey,
          child: Column(
            children: [
              FormBuilderTextField(name: RegistrationFormFields.fullName),
              FormBuilderTextField(
                name: RegistrationFormFields.identificationNumber,
              ),
              FormBuilderField<DateTime>(
                name: RegistrationFormFields.birthDate,
                builder: (field) => const SizedBox.shrink(),
              ),
              FormBuilderTextField(name: RegistrationFormFields.phone),
              FormBuilderTextField(name: RegistrationFormFields.email),
              FormBuilderTextField(name: RegistrationFormFields.residenceCity),
              FormBuilderTextField(name: RegistrationFormFields.eps),
              FormBuilderTextField(
                name: RegistrationFormFields.medicalInsurance,
              ),
              // Never touched by this test: the same field the rider left
              // untouched while editing an existing registration.
              FormBuilderField<BloodType>(
                name: RegistrationFormFields.bloodType,
                builder: (field) => const SizedBox.shrink(),
              ),
              FormBuilderTextField(
                name: RegistrationFormFields.emergencyContactName,
              ),
              FormBuilderTextField(
                name: RegistrationFormFields.emergencyContactPhone,
              ),
              FormBuilderTextField(name: RegistrationFormFields.vehicleId),
              FormBuilderField<bool>(
                name: RegistrationFormFields.shareMedicalInfo,
                initialValue: false,
                builder: (field) => const SizedBox.shrink(),
              ),
              FormBuilderField<bool>(
                name: RegistrationFormFields.allowOrganizerContact,
                initialValue: false,
                builder: (field) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_existingRegistration(BloodType.oPositive));
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

  group(
    'RegistrationFormCubit — bloodType preserved on edit without touching it (2.2)',
    () {
      testWidgets(
        '2.2: editing an existing registration without touching bloodType keeps '
        'the original value in the built registration',
        (tester) async {
          final existing = _existingRegistration(BloodType.bNegative);
          when(
            () => mockUpdate(any(), saveToProfile: any(named: 'saveToProfile')),
          ).thenAnswer((invocation) async {
            final passed =
                invocation.positionalArguments.first as EventRegistrationModel;
            return Right(passed);
          });

          await tester.pumpWidget(_MinimalRegistrationForm(cubit: cubit));
          await tester.pumpAndSettle();

          cubit.initialize(
            eventId: existing.eventId,
            eventName: existing.eventName,
            existingRegistration: existing,
          );

          // _preloadFromExistingRegistration runs after a 100ms delay; pump
          // past it so formKey.currentState.patchValue actually applies.
          await tester.pump(const Duration(milliseconds: 150));

          // The rider never interacts with the blood type field — we go
          // straight to saving, exercising the real (non-seam) _buildRegistration
          // path that reads formKey.currentState.value.
          await cubit.saveRegistration();
          await tester.pump();

          final state = cubit.state;
          expect(state, isA<Data<EventRegistrationModel>>());
          final saved = (state as Data<EventRegistrationModel>).data;
          expect(saved.bloodType, BloodType.bNegative);
        },
      );
    },
  );

  group('RegistrationFormCubit — waiver privacy switches preload on edit '
      '(AC#3, guards cubit lines 166-169)', () {
    testWidgets('editing an existing registration patches shareMedicalInfo and '
        'allowOrganizerContact from the existing registration values', (
      tester,
    ) async {
      final existing = _existingRegistration(
        BloodType.oPositive,
        shareMedicalInfo: true,
        allowOrganizerContact: true,
      );

      await tester.pumpWidget(_MinimalRegistrationForm(cubit: cubit));
      await tester.pumpAndSettle();

      cubit.initialize(
        eventId: existing.eventId,
        eventName: existing.eventName,
        existingRegistration: existing,
      );

      // _preloadFromExistingRegistration runs after a 100ms delay; pump
      // past it so formKey.currentState.patchValue actually applies.
      await tester.pump(const Duration(milliseconds: 150));

      final fields = cubit.formKey.currentState!.fields;
      expect(fields[RegistrationFormFields.shareMedicalInfo]!.value, isTrue);
      expect(
        fields[RegistrationFormFields.allowOrganizerContact]!.value,
        isTrue,
      );
    });
  });

  group('RegistrationFormCubit — legal payload built from the real form '
      '(AC#9/#10, no buildRegistrationOverride seam)', () {
    testWidgets('saveRegistration() without buildRegistrationOverride builds a '
        'registration whose riskAcceptanceVersion, riskAcceptedAt, '
        'shareMedicalInfo and allowOrganizerContact reflect the real form '
        'values (exercises the production _buildRegistration() path, not a '
        'test seam)', (tester) async {
      when(
        () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
      ).thenAnswer((invocation) async {
        final passed =
            invocation.positionalArguments.first as EventRegistrationModel;
        return Right(passed);
      });

      await tester.pumpWidget(_MinimalRegistrationForm(cubit: cubit));
      await tester.pumpAndSettle();

      cubit.initialize(eventId: 'event-1', eventName: 'Rodada Test');
      await tester.pump(const Duration(milliseconds: 60));

      cubit.formKey.currentState?.patchValue({
        RegistrationFormFields.fullName: 'Rider Test',
        RegistrationFormFields.identificationNumber: '123456',
        RegistrationFormFields.birthDate: DateTime(2000, 1, 1),
        RegistrationFormFields.phone: '3001234567',
        RegistrationFormFields.email: 'rider@test.com',
        RegistrationFormFields.residenceCity: 'Bogotá',
        RegistrationFormFields.eps: 'Sura',
        RegistrationFormFields.bloodType: BloodType.oPositive,
        RegistrationFormFields.emergencyContactName: 'Contact Test',
        RegistrationFormFields.emergencyContactPhone: '3007654321',
        RegistrationFormFields.shareMedicalInfo: true,
        RegistrationFormFields.allowOrganizerContact: true,
      });
      await tester.pump();

      await cubit.saveRegistration();
      await tester.pump();

      final state = cubit.state;
      expect(state, isA<Data<EventRegistrationModel>>());
      final saved = (state as Data<EventRegistrationModel>).data;
      expect(saved.riskAcceptanceVersion, 'v0.1-2026-06');
      expect(saved.riskAcceptedAt, isNotNull);
      expect(saved.shareMedicalInfo, isTrue);
      expect(saved.allowOrganizerContact, isTrue);
    });

    testWidgets('saveRegistration() without buildRegistrationOverride reflects '
        'shareMedicalInfo=false/allowOrganizerContact=false when the rider '
        'leaves the privacy switches at their default', (tester) async {
      when(
        () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
      ).thenAnswer((invocation) async {
        final passed =
            invocation.positionalArguments.first as EventRegistrationModel;
        return Right(passed);
      });

      await tester.pumpWidget(_MinimalRegistrationForm(cubit: cubit));
      await tester.pumpAndSettle();

      cubit.initialize(eventId: 'event-1', eventName: 'Rodada Test');
      await tester.pump(const Duration(milliseconds: 60));

      cubit.formKey.currentState?.patchValue({
        RegistrationFormFields.fullName: 'Rider Test',
        RegistrationFormFields.identificationNumber: '123456',
        RegistrationFormFields.birthDate: DateTime(2000, 1, 1),
        RegistrationFormFields.phone: '3001234567',
        RegistrationFormFields.email: 'rider@test.com',
        RegistrationFormFields.residenceCity: 'Bogotá',
        RegistrationFormFields.eps: 'Sura',
        RegistrationFormFields.bloodType: BloodType.oPositive,
        RegistrationFormFields.emergencyContactName: 'Contact Test',
        RegistrationFormFields.emergencyContactPhone: '3007654321',
      });
      await tester.pump();

      await cubit.saveRegistration();
      await tester.pump();

      final state = cubit.state;
      expect(state, isA<Data<EventRegistrationModel>>());
      final saved = (state as Data<EventRegistrationModel>).data;
      expect(saved.shareMedicalInfo, isFalse);
      expect(saved.allowOrganizerContact, isFalse);
    });
  });
}
