// Widget tests for ProfilePage / ProfileContent / ProfileHeader /
// ProfileActionsList.
//
// Covers gaps listed in docs/testing/qa-checklists/profile_QA_CHECKLIST.md
// (Fixes requeridos #1 and #2):
//   - Regression: "Editar info" button must NEVER appear on the profile
//     header/content/page.
//   - Navigation shortcuts ("Mis inscripciones", "Mantenimientos") push the
//     expected named routes.
//   - "Cerrar sesión" opens the confirmation dialog and, on confirm, invokes
//     AuthCubit.signOut() + VehicleCubit.clearVehicles() +
//     ProfileCubit.reset() and navigates to the login route.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/profile/presentation/cubits/analytics_consent_cubit.dart';
import 'package:rideglory/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:rideglory/features/profile/presentation/profile_page.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_content.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_header.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class MockProfileCubit extends MockCubit<ResultState<UserModel>>
    implements ProfileCubit {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockVehicleCubit extends MockCubit<ResultState<List<VehicleModel>>>
    implements VehicleCubit {}

class MockAnalyticsConsentCubit extends MockCubit<ResultState<bool>>
    implements AnalyticsConsentCubit {}

void main() {
  late MockProfileCubit profileCubit;
  late MockAuthCubit authCubit;
  late MockVehicleCubit vehicleCubit;
  late MockAnalyticsConsentCubit analyticsConsentCubit;

  const mockUser = UserModel(
    id: 'user-123',
    fullName: 'Juan Pérez',
    email: 'juan@example.com',
    residenceCity: 'Bogotá',
  );

  setUp(() {
    profileCubit = MockProfileCubit();
    authCubit = MockAuthCubit();
    vehicleCubit = MockVehicleCubit();
    analyticsConsentCubit = MockAnalyticsConsentCubit();

    when(() => profileCubit.state).thenReturn(
      const ResultState<UserModel>.data(data: mockUser),
    );
    when(() => profileCubit.fetchProfile()).thenAnswer((_) async {});
    when(() => profileCubit.reset()).thenReturn(null);

    when(() => authCubit.signOut()).thenAnswer((_) async {});

    when(() => vehicleCubit.clearVehicles()).thenReturn(null);

    when(() => analyticsConsentCubit.state).thenReturn(
      const ResultState<bool>.data(data: true),
    );
    when(() => analyticsConsentCubit.load()).thenAnswer((_) async {});

    GetIt.I.allowReassignment = true;
    GetIt.I.registerFactory<AnalyticsConsentCubit>(
      () => analyticsConsentCubit,
    );
  });

  tearDown(() {
    if (GetIt.I.isRegistered<AnalyticsConsentCubit>()) {
      GetIt.I.unregister<AnalyticsConsentCubit>();
    }
    GetIt.I.allowReassignment = false;
  });

  Widget buildTestApp({String initialLocation = '/profile'}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/profile',
          name: AppRoutes.home,
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/my-registrations',
          name: AppRoutes.myRegistrations,
          builder: (context, state) =>
              const Scaffold(body: Text('my-registrations-screen')),
        ),
        GoRoute(
          path: '/maintenances',
          name: AppRoutes.maintenances,
          builder: (context, state) =>
              const Scaffold(body: Text('maintenances-screen')),
        ),
        GoRoute(
          path: '/login',
          name: AppRoutes.login,
          builder: (context, state) =>
              const Scaffold(body: Text('login-screen')),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileCubit>.value(value: profileCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<VehicleCubit>.value(value: vehicleCubit),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        routerConfig: router,
      ),
    );
  }

  group('ProfilePage — render de datos del usuario', () {
    testWidgets('muestra el AppBar con título "Mi perfil"', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Mi perfil'), findsOneWidget);
    });

    testWidgets(
      'muestra nombre, email y ciudad del usuario cargado',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Juan Pérez'), findsOneWidget);
        expect(find.text('juan@example.com'), findsOneWidget);
        expect(find.text('Bogotá'), findsOneWidget);
      },
    );
  });

  group(
    'Regresión — el botón "Editar info" NUNCA debe aparecer',
    () {
      testWidgets(
        'ProfilePage no contiene ningún texto/ícono de edición de perfil',
        (tester) async {
          await tester.pumpWidget(buildTestApp());
          await tester.pumpAndSettle();

          expect(find.textContaining('Editar'), findsNothing);
          expect(find.byIcon(Icons.edit), findsNothing);
          expect(find.byIcon(Icons.edit_outlined), findsNothing);
        },
      );

      testWidgets(
        'ProfileHeader en aislamiento tampoco expone ningún botón de edición',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                AppLocalizations.delegate,
              ],
              supportedLocales: const [Locale('es')],
              home: const Scaffold(
                body: ProfileHeader(user: mockUser),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.textContaining('Editar'), findsNothing);
          expect(find.byType(GestureDetector), findsNothing);
          expect(find.byType(IconButton), findsNothing);
        },
      );
    },
  );

  group('ProfilePage — atajos de navegación', () {
    testWidgets(
      'tocar "Mis inscripciones" navega a la ruta myRegistrations',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Mis inscripciones'));
        await tester.pumpAndSettle();

        expect(find.text('my-registrations-screen'), findsOneWidget);
      },
    );

    testWidgets(
      'tocar "Mantenimientos" navega a la ruta maintenances',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Mantenimientos'));
        await tester.pumpAndSettle();

        expect(find.text('maintenances-screen'), findsOneWidget);
      },
    );
  });

  group('ProfilePage — logout con confirmación', () {
    testWidgets(
      'tocar "Cerrar sesión" abre el diálogo de confirmación',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cerrar sesión').first);
        await tester.pumpAndSettle();

        expect(
          find.text('¿Estás seguro de que deseas cerrar sesión?'),
          findsOneWidget,
        );
        verifyNever(() => authCubit.signOut());
      },
    );

    testWidgets(
      'cancelar el diálogo no cierra sesión y permanece en el perfil',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cerrar sesión').first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        verifyNever(() => authCubit.signOut());
        verifyNever(() => vehicleCubit.clearVehicles());
        verifyNever(() => profileCubit.reset());
        expect(find.text('Mi perfil'), findsOneWidget);
      },
    );

    testWidgets(
      'confirmar el diálogo invoca signOut, clearVehicles y reset, y navega a login',
      (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cerrar sesión').first);
        await tester.pumpAndSettle();

        // El botón de confirmación en el diálogo también dice "Cerrar
        // sesión" (confirmLabel = context.l10n.auth_logout); tras abrir el
        // diálogo hay dos matches: el ítem de la lista y el botón del modal.
        await tester.tap(find.text('Cerrar sesión').last);
        await tester.pumpAndSettle();

        verify(() => authCubit.signOut()).called(1);
        verify(() => vehicleCubit.clearVehicles()).called(1);
        verify(() => profileCubit.reset()).called(1);
        expect(find.text('login-screen'), findsOneWidget);
      },
    );
  });

  group('ProfileContent — smoke test directo', () {
    testWidgets(
      'renderiza header, stats y acciones sin depender de ProfilePage',
      (tester) async {
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<ProfileCubit>.value(value: profileCubit),
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<VehicleCubit>.value(value: vehicleCubit),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                AppLocalizations.delegate,
              ],
              supportedLocales: const [Locale('es')],
              home: const Scaffold(
                body: ProfileContent(user: mockUser),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Juan Pérez'), findsOneWidget);
        expect(find.text('Mis inscripciones'), findsOneWidget);
        expect(find.text('Mantenimientos'), findsOneWidget);
        expect(find.text('Cerrar sesión'), findsOneWidget);
        expect(find.textContaining('Editar'), findsNothing);
      },
    );
  });
}
