// Tests for the REAL RegistrationFormContent._onNext() interceptor
// (legal-consentimientos-fase5, Bloque B). These drive the actual wizard
// "Siguiente" button wired to RegistrationFormContent and the real
// MedicalConsentSheet, guarding the Ley 1581 gate end-to-end.
//
// El consentimiento médico es POR INSCRIPCIÓN (no por usuario/dispositivo): se
// guarda en el propio RegistrationFormCubit. El gate se dispara al SALIR del
// paso Médico (índice 1) — donde el rider ingresó sus datos médicos — solo si
// la inscripción aún no tiene consentimiento:
//
// - sin consentimiento -> abre el sheet y permanece en el paso Médico.
// - autorizar en el sheet -> registra el consentimiento y avanza a Emergencia.
// - consentimiento ya registrado -> omite el sheet y avanza a Emergencia.
// - "No autorizar" -> descarta el sheet y permanece en el paso Médico.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/core/services/place_service.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/add_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/update_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/registration_form_view.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_rider_profile_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/save_rider_profile_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/l10n/app_localizations.dart';

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

class MockVehicleCubit extends MockCubit<ResultState<List<VehicleModel>>>
    implements VehicleCubit {}

class MockPlaceService extends Mock implements PlaceService {}

final _testEvent = EventModel(
  id: 'event-1',
  ownerId: 'owner-1',
  name: 'Rodada de prueba',
  description: 'desc',
  startDate: DateTime(2026, 8, 1),
  difficulty: EventDifficulty.one,
  meetingTime: DateTime(2026, 8, 1, 8),
  eventType: EventType.onRoad,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAddEventRegistrationUseCase addUseCase;
  late MockUpdateEventRegistrationUseCase updateUseCase;
  late MockGetRiderProfileUseCase getRiderProfileUseCase;
  late MockSaveRiderProfileUseCase saveRiderProfileUseCase;
  late MockAuthService authService;
  late MockAnalyticsService analyticsService;
  late RegistrationFormCubit registrationFormCubit;
  late MockVehicleCubit vehicleCubit;

  setUp(() {
    // AppCityAutocomplete (used by RegistrationPersonalStep) reads
    // getIt<PlaceService>() unconditionally at build time.
    if (!GetIt.instance.isRegistered<PlaceService>()) {
      GetIt.instance.registerSingleton<PlaceService>(MockPlaceService());
    }

    addUseCase = MockAddEventRegistrationUseCase();
    updateUseCase = MockUpdateEventRegistrationUseCase();
    getRiderProfileUseCase = MockGetRiderProfileUseCase();
    saveRiderProfileUseCase = MockSaveRiderProfileUseCase();
    authService = MockAuthService();
    analyticsService = MockAnalyticsService();
    when(
      () => analyticsService.logEvent(any(), any()),
    ).thenAnswer((_) async {});

    registrationFormCubit = RegistrationFormCubit(
      addUseCase,
      updateUseCase,
      getRiderProfileUseCase,
      saveRiderProfileUseCase,
      authService,
      analyticsService,
    );

    vehicleCubit = MockVehicleCubit();
    when(
      () => vehicleCubit.state,
    ).thenReturn(const ResultState<List<VehicleModel>>.initial());
    when(() => vehicleCubit.fetchMyVehicles()).thenAnswer((_) async {});
    when(() => vehicleCubit.availableVehicles).thenReturn(const []);
  });

  tearDown(() {
    registrationFormCubit.close();
    if (GetIt.instance.isRegistered<PlaceService>()) {
      GetIt.instance.unregister<PlaceService>();
    }
  });

  /// Fills the step-0 (Personal) fields directly on the shared [FormBuilder]
  /// so `validateStepFields` passes, without driving each text field/date
  /// picker through the UI.
  void fillPersonalStepFields() {
    registrationFormCubit.formKey.currentState?.patchValue({
      RegistrationFormFields.fullName: 'Juan Pérez',
      RegistrationFormFields.identificationNumber: '123456789',
      RegistrationFormFields.birthDate: DateTime(1990, 1, 1),
      RegistrationFormFields.phone: '3001234567',
      RegistrationFormFields.email: 'juan@test.com',
      RegistrationFormFields.residenceCity: 'Medellín',
    });
  }

  /// Fills the step-1 (Medical) fields so `validateStepFields` passes and the
  /// wizard can leave the Medical step (where the Ley 1581 gate fires).
  void fillMedicalStepFields() {
    registrationFormCubit.formKey.currentState?.patchValue({
      RegistrationFormFields.eps: 'Sura',
      RegistrationFormFields.bloodType: BloodType.oPositive,
    });
  }

  /// Advances the wizard from Personal (step 0) to Medical (step 1). No consent
  /// gate fires here — it only triggers when leaving the Medical step.
  Future<void> advanceToMedicalStep(WidgetTester tester) async {
    fillPersonalStepFields();
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    await tester.pump();
  }

  Widget buildApp() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegistrationFormCubit>.value(value: registrationFormCubit),
        BlocProvider<VehicleCubit>.value(value: vehicleCubit),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  Scaffold(body: RegistrationFormView(event: _testEvent)),
            ),
          ],
        ),
        theme: AppTheme.darkTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
      ),
    );
  }

  /// Taps "Siguiente" and pumps enough for the async gate + modal open, without
  /// pumpAndSettle (the wizard never fully settles).
  Future<void> tapNextAndOpenGate(WidgetTester tester) async {
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
    'opens the medical-consent sheet when leaving the Medical step and consent '
    'has not been given for this registration',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      fillMedicalStepFields();
      await advanceToMedicalStep(tester);
      expect(find.text('Información Médica'), findsOneWidget);

      await tapNextAndOpenGate(tester);

      expect(find.text('Autorización de datos médicos'), findsOneWidget);
      expect(find.text('Contacto de Emergencia'), findsNothing);
    },
  );

  testWidgets(
    'authorizing the consent records it and advances to the Emergency step',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      fillMedicalStepFields();
      await advanceToMedicalStep(tester);

      await tapNextAndOpenGate(tester);
      expect(find.text('Autorización de datos médicos'), findsOneWidget);

      await tester.tap(find.text('Autorizar'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(registrationFormCubit.medicalConsentAcceptedAt, isNotNull);
      expect(find.text('Autorización de datos médicos'), findsNothing);
      expect(find.text('Contacto de Emergencia'), findsOneWidget);
    },
  );

  testWidgets(
    'skips the consent sheet and advances to the Emergency step when consent '
    'was already recorded for this registration',
    (tester) async {
      registrationFormCubit.acceptMedicalConsent(DateTime(2026, 7, 2));

      await tester.pumpWidget(buildApp());
      await tester.pump();
      fillMedicalStepFields();
      await advanceToMedicalStep(tester);

      await tapNextAndOpenGate(tester);

      expect(find.text('Autorización de datos médicos'), findsNothing);
      expect(find.text('Contacto de Emergencia'), findsOneWidget);
    },
  );

  testWidgets('declining the consent keeps the rider on the Medical step', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    fillMedicalStepFields();
    await advanceToMedicalStep(tester);

    await tapNextAndOpenGate(tester);
    expect(find.text('Autorización de datos médicos'), findsOneWidget);

    await tester.tap(find.text('No autorizar'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(registrationFormCubit.medicalConsentAcceptedAt, isNull);
    expect(find.text('Autorización de datos médicos'), findsNothing);
    expect(find.text('Contacto de Emergencia'), findsNothing);
    expect(find.text('Información Médica'), findsOneWidget);
  });
}
