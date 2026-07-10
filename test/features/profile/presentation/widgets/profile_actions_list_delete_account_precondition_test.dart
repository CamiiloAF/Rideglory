// Widget tests for the "Eliminar cuenta" precondition wired in
// ProfileActionsList (AC1, AC2, AC3, AC4, AC12 of eliminacion-cuenta-phase-03):
//   - No active organizer events (draft/scheduled/inProgress) -> navigates
//     straight to AppRoutes.deleteAccount.
//   - Cancelled/finished events (or none) do NOT block navigation.
//   - At least one active organizer event -> blocks navigation and shows
//     ActiveEventsBlockSheet with the blocking event's name; tapping its CTA
//     navigates to AppRoutes.myEvents instead.
//   - Re-evaluated on every tap (AC4): first tap blocked, second tap (after
//     the mock now returns no active events) navigates through.
//   - A failed GetMyEventsUseCase call does not navigate and does not crash
//     (avoids a silent precondition bypass).

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
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_events_use_case.dart';
import 'package:rideglory/features/profile/presentation/cubits/analytics_consent_cubit.dart';
import 'package:rideglory/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_actions_list.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class MockGetMyEventsUseCase extends Mock implements GetMyEventsUseCase {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockVehicleCubit extends MockCubit<ResultState<List<VehicleModel>>>
    implements VehicleCubit {}

class MockProfileCubit extends MockCubit<ResultState<UserModel>>
    implements ProfileCubit {}

class MockAnalyticsConsentCubit extends MockCubit<ResultState<bool>>
    implements AnalyticsConsentCubit {}

EventModel _buildEvent({required String name, required EventState state}) {
  return EventModel(
    ownerId: 'owner-1',
    name: name,
    description: 'desc',
    startDate: DateTime(2026, 8, 1),
    difficulty: EventDifficulty.one,
    meetingTime: DateTime(2026, 8, 1, 8),
    eventType: EventType.onRoad,
    state: state,
  );
}

void main() {
  late MockGetMyEventsUseCase getMyEventsUseCase;
  late MockAuthCubit authCubit;
  late MockVehicleCubit vehicleCubit;
  late MockProfileCubit profileCubit;
  late MockAnalyticsConsentCubit analyticsConsentCubit;

  setUp(() {
    getMyEventsUseCase = MockGetMyEventsUseCase();
    authCubit = MockAuthCubit();
    vehicleCubit = MockVehicleCubit();
    profileCubit = MockProfileCubit();
    analyticsConsentCubit = MockAnalyticsConsentCubit();
    when(() => analyticsConsentCubit.state).thenReturn(
      const ResultState<bool>.data(data: true),
    );

    GetIt.I.allowReassignment = true;
    GetIt.I.registerFactory<GetMyEventsUseCase>(() => getMyEventsUseCase);
  });

  tearDown(() {
    if (GetIt.I.isRegistered<GetMyEventsUseCase>()) {
      GetIt.I.unregister<GetMyEventsUseCase>();
    }
    GetIt.I.allowReassignment = false;
  });

  Widget buildTestApp() {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          name: AppRoutes.home,
          builder: (context, state) => Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<AuthCubit>.value(value: authCubit),
                BlocProvider<VehicleCubit>.value(value: vehicleCubit),
                BlocProvider<ProfileCubit>.value(value: profileCubit),
                BlocProvider<AnalyticsConsentCubit>.value(
                  value: analyticsConsentCubit,
                ),
              ],
              child: const ProfileActionsList(),
            ),
          ),
        ),
        GoRoute(
          path: '/profile/delete-account',
          name: AppRoutes.deleteAccount,
          builder: (context, state) =>
              const Scaffold(body: Text('delete-account-screen')),
        ),
        GoRoute(
          path: '/events/mine',
          name: AppRoutes.myEvents,
          builder: (context, state) =>
              const Scaffold(body: Text('my-events-screen')),
        ),
      ],
    );

    return MaterialApp.router(
      theme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      routerConfig: router,
    );
  }

  Future<void> tapDeleteAccount(WidgetTester tester) async {
    await tester.tap(find.text('Eliminar cuenta'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'sin eventos activos como organizador navega directo a deleteAccount',
    (tester) async {
      when(
        () => getMyEventsUseCase(),
      ).thenAnswer((_) async => const Right(<EventModel>[]));

      await tester.pumpWidget(buildTestApp());
      await tapDeleteAccount(tester);

      expect(find.text('delete-account-screen'), findsOneWidget);
    },
  );

  testWidgets(
    'eventos cancelados/finalizados no bloquean la navegación',
    (tester) async {
      when(() => getMyEventsUseCase()).thenAnswer(
        (_) async => Right(<EventModel>[
          _buildEvent(name: 'Rodada vieja', state: EventState.cancelled),
          _buildEvent(name: 'Rodada terminada', state: EventState.finished),
        ]),
      );

      await tester.pumpWidget(buildTestApp());
      await tapDeleteAccount(tester);

      expect(find.text('delete-account-screen'), findsOneWidget);
    },
  );

  testWidgets(
    'con un evento activo como organizador bloquea y muestra el sheet con su nombre',
    (tester) async {
      when(() => getMyEventsUseCase()).thenAnswer(
        (_) async => Right(<EventModel>[
          _buildEvent(name: 'Rodada al Nevado', state: EventState.scheduled),
        ]),
      );

      await tester.pumpWidget(buildTestApp());
      await tapDeleteAccount(tester);

      expect(find.text('delete-account-screen'), findsNothing);
      expect(find.textContaining('Rodada al Nevado'), findsOneWidget);
    },
  );

  testWidgets(
    'el CTA del sheet de bloqueo navega a myEvents',
    (tester) async {
      when(() => getMyEventsUseCase()).thenAnswer(
        (_) async => Right(<EventModel>[
          _buildEvent(name: 'Rodada al Nevado', state: EventState.draft),
        ]),
      );

      await tester.pumpWidget(buildTestApp());
      await tapDeleteAccount(tester);

      await tester.tap(find.text('Ver mis eventos'));
      await tester.pumpAndSettle();

      expect(find.text('my-events-screen'), findsOneWidget);
    },
  );

  testWidgets(
    'se re-evalúa en cada tap: bloqueado primero, permitido después (AC4)',
    (tester) async {
      var callCount = 0;
      when(() => getMyEventsUseCase()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return Right(<EventModel>[
            _buildEvent(
              name: 'Rodada en curso',
              state: EventState.inProgress,
            ),
          ]);
        }
        return const Right(<EventModel>[]);
      });

      await tester.pumpWidget(buildTestApp());

      await tapDeleteAccount(tester);
      expect(find.text('delete-account-screen'), findsNothing);

      // Dismiss the blocking sheet before tapping again.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      await tapDeleteAccount(tester);
      expect(find.text('delete-account-screen'), findsOneWidget);
      expect(callCount, 2);
    },
  );

  testWidgets(
    'si falla la verificación no navega ni bloquea silenciosamente',
    (tester) async {
      when(() => getMyEventsUseCase()).thenAnswer(
        (_) async =>
            const Left(DomainException(message: 'network error')),
      );

      await tester.pumpWidget(buildTestApp());
      await tapDeleteAccount(tester);

      expect(find.text('delete-account-screen'), findsNothing);
      expect(find.textContaining('Rodada'), findsNothing);
    },
  );
}
