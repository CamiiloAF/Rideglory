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
import 'package:dartz/dartz.dart';
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
import 'package:rideglory/features/event_registration/domain/model/registration_with_event.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/registration_form_content.dart';
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

class MockMyRegistrationsCubit
    extends MockCubit<ResultState<List<RegistrationWithEvent>>>
    implements MyRegistrationsCubit {}

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

/// A vehicle available in the rider's garage, used by the wizard's vehicle
/// step (step 4) so `VehicleSelectorField` (and its `vehicleId` FormBuilder
/// field) actually mounts.
const _testVehicle = VehicleModel(
  id: 'vehicle-1',
  name: 'Mi moto',
  brand: 'Yamaha',
  model: 'MT-07',
  currentMileage: 1000,
);

/// A fully-valid saved registration returned by the (mocked) add use case on
/// a successful submission.
EventRegistrationModel _fakeSavedRegistration() => EventRegistrationModel(
  id: 'reg-1',
  eventId: _testEvent.id!,
  eventName: _testEvent.name,
  userId: 'u1',
  fullName: 'Juan Pérez',
  identificationNumber: '123456789',
  birthDate: DateTime(1990, 1, 1),
  phone: '3001234567',
  email: 'juan@test.com',
  residenceCity: 'Medellín',
  eps: 'Sura',
  bloodType: BloodType.oPositive,
  emergencyContactName: 'Ana García',
  emergencyContactPhone: '3109876543',
  vehicleId: _testVehicle.id,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_fakeSavedRegistration());
  });

  late MockAddEventRegistrationUseCase addUseCase;
  late MockUpdateEventRegistrationUseCase updateUseCase;
  late MockGetRiderProfileUseCase getRiderProfileUseCase;
  late MockSaveRiderProfileUseCase saveRiderProfileUseCase;
  late MockAuthService authService;
  late MockAnalyticsService analyticsService;
  late RegistrationFormCubit registrationFormCubit;
  late MockVehicleCubit vehicleCubit;
  late MockMyRegistrationsCubit myRegistrationsCubit;

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

    myRegistrationsCubit = MockMyRegistrationsCubit();
    when(
      () => myRegistrationsCubit.state,
    ).thenReturn(const ResultState<List<RegistrationWithEvent>>.initial());
    when(
      () => myRegistrationsCubit.onChangeRegistration(any()),
    ).thenReturn(null);
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

  /// Fills the step-2 (Emergency contact) fields so `validateStepFields`
  /// passes and the wizard can leave to the Vehicle step.
  void fillEmergencyStepFields() {
    registrationFormCubit.formKey.currentState?.patchValue({
      RegistrationFormFields.emergencyContactName: 'Ana García',
      RegistrationFormFields.emergencyContactPhone: '3109876543',
    });
  }

  /// Same host as [buildApp] but nests [RegistrationFormView] behind a pushed
  /// route (instead of being the initial route) so `context.pop()` at the end
  /// of a successful submission (case 1.10) can be observed: the pushed route
  /// is removed and the caller ("Ir al formulario") screen comes back.
  Widget buildAppWithPushedRoute() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegistrationFormCubit>.value(value: registrationFormCubit),
        BlocProvider<VehicleCubit>.value(value: vehicleCubit),
        BlocProvider<MyRegistrationsCubit>.value(value: myRegistrationsCubit),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => context.pushNamed('registration'),
                    child: const Text('Ir al formulario'),
                  ),
                ),
              ),
            ),
            GoRoute(
              name: 'registration',
              path: '/registration',
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

  // QA_CHECKLIST case 11B.2 — auto-fetch de vehículos cuando VehicleCubit
  // está en estado `initial` (el rider llegó directo al formulario sin pasar
  // por el garaje).
  group('vehicle auto-fetch (case 11B.2)', () {
    testWidgets(
      'fetches the rider vehicles on mount when VehicleCubit is in initial '
      'state, so the vehicle step never shows an infinite spinner',
      (tester) async {
        // setUp() already stubs vehicleCubit.state as ResultState.initial().
        await tester.pumpWidget(buildApp());
        await tester.pump();

        verify(() => vehicleCubit.fetchMyVehicles()).called(1);
      },
    );

    testWidgets(
      'does NOT re-fetch vehicles when VehicleCubit already has data on mount',
      (tester) async {
        when(
          () => vehicleCubit.state,
        ).thenReturn(const ResultState<List<VehicleModel>>.data(data: [_testVehicle]));

        await tester.pumpWidget(buildApp());
        await tester.pump();

        verifyNever(() => vehicleCubit.fetchMyVehicles());
      },
    );
  });

  // QA_CHECKLIST case 11A.2 — bloqueo de avance sin campos requeridos.
  group('blocks advancing without required fields (case 11A.2)', () {
    testWidgets(
      'tapping "Siguiente" on the Personal step with every field empty stays '
      'on the same step and surfaces the validation errors',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pump();
        expect(find.text('Información Personal'), findsOneWidget);

        await tester.tap(find.text('Siguiente'));
        await tester.pump();
        await tester.pump();

        // Never advanced to the next step.
        expect(find.text('Información Médica'), findsNothing);
        expect(find.text('Información Personal'), findsOneWidget);
        // Validation errors for the required fields are visible.
        expect(
          find.text('El nombre completo es requerido'),
          findsOneWidget,
        );
        expect(find.text('El celular es requerido'), findsOneWidget);
      },
    );

    testWidgets(
      'leaving a single required field empty (fullName) still blocks the '
      'advance and shows that field\'s error',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pump();

        registrationFormCubit.formKey.currentState?.patchValue({
          RegistrationFormFields.identificationNumber: '123456789',
          RegistrationFormFields.birthDate: DateTime(1990, 1, 1),
          RegistrationFormFields.phone: '3001234567',
          RegistrationFormFields.email: 'juan@test.com',
          RegistrationFormFields.residenceCity: 'Medellín',
        });

        await tester.tap(find.text('Siguiente'));
        await tester.pump();
        await tester.pump();

        expect(find.text('Información Médica'), findsNothing);
        expect(find.text('Información Personal'), findsOneWidget);
        expect(
          find.text('El nombre completo es requerido'),
          findsOneWidget,
        );
      },
    );
  });

  // QA_CHECKLIST case 1.10 — snackbar de confirmación + cierre de página tras
  // una inscripción exitosa.
  group('success snackbar + page close on submit (case 1.10)', () {
    testWidgets(
      'completing the wizard successfully shows the confirmation snackbar and '
      'pops the registration form page',
      (tester) async {
        when(
          () => vehicleCubit.state,
        ).thenReturn(const ResultState<List<VehicleModel>>.data(data: [_testVehicle]));
        when(
          () => addUseCase(any(), saveToProfile: any(named: 'saveToProfile')),
        ).thenAnswer((_) async => Right(_fakeSavedRegistration()));

        await tester.pumpWidget(buildAppWithPushedRoute());
        await tester.pump();

        await tester.tap(find.text('Ir al formulario'));
        await tester.pumpAndSettle();
        expect(find.byType(RegistrationFormContent), findsOneWidget);

        // Personal step.
        fillPersonalStepFields();
        await tester.tap(find.text('Siguiente'));
        await tester.pump();
        await tester.pump();

        // Medical step + Ley 1581 consent gate.
        fillMedicalStepFields();
        await tester.tap(find.text('Siguiente'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Autorizar'));
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Emergency step.
        fillEmergencyStepFields();
        await tester.tap(find.text('Siguiente'));
        await tester.pump();
        await tester.pump();

        // Vehicle step: pick the vehicle registered on VehicleCubit.
        registrationFormCubit.formKey.currentState?.patchValue({
          RegistrationFormFields.vehicleId: _testVehicle.id,
        });
        await tester.tap(find.text('Confirmar Inscripción'));
        await tester.pumpAndSettle();
        expect(find.text('Aceptación de riesgo'), findsOneWidget);

        // Accept the risk waiver -> submits the registration.
        await tester.tap(find.text('Entiendo, inscribirme'));
        await tester.pumpAndSettle();

        verify(
          () => addUseCase(any(), saveToProfile: any(named: 'saveToProfile')),
        ).called(1);
        verify(
          () => myRegistrationsCubit.onChangeRegistration(any()),
        ).called(1);
        // Confirmation snackbar shown.
        expect(
          find.text(
            'Inscripción enviada exitosamente. Está pendiente de aprobación.',
          ),
          findsOneWidget,
        );
        // The registration form page popped: back on the caller screen.
        expect(find.text('Ir al formulario'), findsOneWidget);
        expect(find.byType(RegistrationFormContent), findsNothing);
      },
    );
  });
}
