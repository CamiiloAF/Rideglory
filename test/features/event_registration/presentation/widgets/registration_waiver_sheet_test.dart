// Widget tests — RegistrationWaiverSheet
// Covers: render, nullable owner, loading state, the differentiated error
// branches (underage / generic + backend UNDERAGE_RIDER), accepting (drives the
// cubit directly), cancel/dismiss and success-returns. La fecha de nacimiento es
// editable y requerida en la inscripción, así que ya no hay atajo "Ir a mi
// perfil" desde el waiver.

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/add_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/update_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/presentation/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_waiver_sheet.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/rider_profile_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_rider_profile_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/save_rider_profile_use_case.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

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

EventModel _buildEvent({String? ownerName}) => EventModel(
  ownerId: 'owner-1',
  ownerName: ownerName,
  name: 'Rodada de prueba',
  description: 'Descripción',
  startDate: DateTime(2026, 8, 1),
  difficulty: EventDifficulty.two,
  meetingTime: DateTime(2026, 8, 1, 7),
  eventType: EventType.onRoad,
);

EventRegistrationModel _fakeRegistration() => EventRegistrationModel(
  eventId: 'e1',
  eventName: 'Rodada de prueba',
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
    registerFallbackValue(const RiderProfileModel(userId: ''));
    registerFallbackValue(_fakeRegistration());
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

  /// Host with a real [GoRouter] so the sheet's modal route (opened with
  /// `useRootNavigator: true`) and its `context.pushNamed(editProfile)` both
  /// resolve. Tapping "Abrir" opens the sheet and forwards its result to
  /// [onResult].
  Widget host({
    required EventModel event,
    ValueChanged<EventRegistrationModel?>? onResult,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider.value(
            value: cubit,
            child: Builder(
              builder: (innerContext) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await showRegistrationWaiverSheet(
                        context: innerContext,
                        event: event,
                      );
                      onResult?.call(result);
                    },
                    child: const Text('Abrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          name: AppRoutes.editProfile,
          path: AppRoutes.editProfile,
          builder: (context, state) =>
              const Scaffold(body: Text('Editar perfil')),
        ),
      ],
    );
    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      routerConfig: router,
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  group('RegistrationWaiverSheet — render', () {
    testWidgets('renders title, legal body and accept/cancel buttons', (
      tester,
    ) async {
      await tester.pumpWidget(host(event: _buildEvent()));
      await openSheet(tester);

      expect(find.text('Aceptación de riesgo'), findsOneWidget);
      expect(find.byType(AppButton), findsNWidgets(2));
    });

    testWidgets('shows the organizer name when event.ownerName is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(event: _buildEvent(ownerName: 'Carlos Organizador')),
      );
      await openSheet(tester);

      expect(find.text('Carlos Organizador'), findsOneWidget);
    });

    testWidgets('does not render an organizer name widget when null', (
      tester,
    ) async {
      await tester.pumpWidget(host(event: _buildEvent()));
      await openSheet(tester);

      expect(find.text('Carlos Organizador'), findsNothing);
    });
  });

  group('RegistrationWaiverSheet — loading state', () {
    testWidgets(
      'accept button shows loading and is disabled while the submission '
      'is pending',
      (tester) async {
        final completer =
            Completer<Either<DomainException, EventRegistrationModel>>();
        cubit.birthDateOverrideForTesting = DateTime(1990);
        cubit.buildRegistrationOverride = () => _fakeRegistration();
        when(
          () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(host(event: _buildEvent()));
        await openSheet(tester);

        await tester.tap(find.byType(AppButton).first);
        await tester.pump();

        final button = tester.widget<AppButton>(find.byType(AppButton).first);
        expect(button.isLoading, isTrue);
        expect(button.onPressed, isNull);

        completer.complete(Right(_fakeRegistration()));
        await tester.pumpAndSettle();
      },
    );
  });

  group('RegistrationWaiverSheet — error branches', () {
    testWidgets('underage error shows the dedicated title and message', (
      tester,
    ) async {
      cubit.birthDateOverrideForTesting = DateTime(
        DateTime.now().year - 17,
        DateTime.now().month,
        DateTime.now().day,
      );

      await tester.pumpWidget(host(event: _buildEvent()));
      await openSheet(tester);

      await tester.tap(find.byType(AppButton).first);
      await tester.pumpAndSettle();

      expect(find.text('No cumples la edad mínima'), findsOneWidget);
      expect(
        find.text(
          'Debes tener al menos 18 años para inscribirte en una rodada.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ir a mi perfil'), findsNothing);
    });

    testWidgets(
      'backend UNDERAGE_RIDER error shows the dedicated underage title/'
      'message, never the raw server text',
      (tester) async {
        cubit.birthDateOverrideForTesting = DateTime(1990);
        cubit.buildRegistrationOverride = () => _fakeRegistration();
        when(
          () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
        ).thenAnswer(
          (_) async => const Left(DomainException(message: 'UNDERAGE_RIDER')),
        );

        await tester.pumpWidget(host(event: _buildEvent()));
        await openSheet(tester);

        await tester.tap(find.byType(AppButton).first);
        await tester.pumpAndSettle();

        expect(find.text('No cumples la edad mínima'), findsOneWidget);
        expect(
          find.text(
            'Debes tener al menos 18 años para inscribirte en una rodada.',
          ),
          findsOneWidget,
        );
        expect(find.text('UNDERAGE_RIDER'), findsNothing);
        expect(find.text('Ir a mi perfil'), findsNothing);
      },
    );

    testWidgets(
      'generic/server error shows the raw message with no title and no '
      'profile button',
      (tester) async {
        cubit.birthDateOverrideForTesting = DateTime(1990);
        cubit.buildRegistrationOverride = () => _fakeRegistration();
        when(
          () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
        ).thenAnswer(
          (_) async => const Left(
            DomainException(message: 'Error genérico del servidor'),
          ),
        );

        await tester.pumpWidget(host(event: _buildEvent()));
        await openSheet(tester);

        await tester.tap(find.byType(AppButton).first);
        await tester.pumpAndSettle();

        expect(find.text('Error genérico del servidor'), findsOneWidget);
        expect(find.text('No cumples la edad mínima'), findsNothing);
        expect(find.text('Ir a mi perfil'), findsNothing);
      },
    );
  });

  group('RegistrationWaiverSheet — accept / cancel / success', () {
    testWidgets(
      'accepting drives the cubit submission (calls the add use case)',
      (tester) async {
        cubit.birthDateOverrideForTesting = DateTime(1990);
        cubit.buildRegistrationOverride = () => _fakeRegistration();
        when(
          () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
        ).thenAnswer((_) async => Right(_fakeRegistration()));

        await tester.pumpWidget(host(event: _buildEvent()));
        await openSheet(tester);

        await tester.tap(find.byType(AppButton).first);
        await tester.pumpAndSettle();

        verify(
          () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
        ).called(1);
      },
    );

    testWidgets('cancel dismisses the sheet without submitting', (
      tester,
    ) async {
      await tester.pumpWidget(host(event: _buildEvent()));
      await openSheet(tester);
      expect(find.text('Aceptación de riesgo'), findsOneWidget);

      await tester.tap(find.byType(AppButton).last);
      await tester.pumpAndSettle();

      expect(find.text('Aceptación de riesgo'), findsNothing);
      verifyNever(
        () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
      );
    });

    testWidgets(
      'a successful submission dismisses the sheet and returns the saved '
      'registration to the caller',
      (tester) async {
        final saved = _fakeRegistration();
        cubit.birthDateOverrideForTesting = DateTime(1990);
        cubit.buildRegistrationOverride = () => saved;
        when(
          () => mockAdd(any(), saveToProfile: any(named: 'saveToProfile')),
        ).thenAnswer((_) async => Right(saved));

        EventRegistrationModel? result;
        var resultReceived = false;
        await tester.pumpWidget(
          host(
            event: _buildEvent(),
            onResult: (value) {
              result = value;
              resultReceived = true;
            },
          ),
        );
        await openSheet(tester);

        await tester.tap(find.byType(AppButton).first);
        await tester.pumpAndSettle();

        expect(find.text('Aceptación de riesgo'), findsNothing);
        expect(resultReceived, isTrue);
        expect(result, isNotNull);
      },
    );
  });
}
