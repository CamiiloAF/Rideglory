// Widget tests for SignupView.
//
// Covers form validation (name/email/password/confirm password rules),
// the required-terms guard, and the happy path invoking
// AuthCubit.signUpWithEmail with the trimmed form values. AuthCubit is
// mocked (bloc_test's MockCubit) — no real Firebase/service call.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/signup/presentation/signup_view.dart';
import 'package:rideglory/features/authentication/signup/presentation/widgets/signup_form.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

Widget _wrap(AuthCubit authCubit) {
  final router = GoRouter(
    initialLocation: AppRoutes.signup,
    routes: [
      GoRoute(
        name: AppRoutes.signup,
        path: AppRoutes.signup,
        builder: (_, _) => BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const SignupView(),
        ),
      ),
      GoRoute(
        name: AppRoutes.login,
        path: AppRoutes.login,
        builder: (_, _) => const Scaffold(body: SizedBox()),
      ),
      GoRoute(
        name: AppRoutes.home,
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: SizedBox()),
      ),
    ],
  );

  return MaterialApp.router(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    routerConfig: router,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
  );
}

// "Crear cuenta" also appears in the SignupHeading title, so the submit
// button must be located scoped to SignupForm to avoid ambiguous finders.
Finder get _submitButtonFinder => find.descendant(
  of: find.byType(SignupForm),
  matching: find.text('Crear cuenta'),
);

// The signup form is tall (4 fields + terms + button); use a bigger test
// surface so tap() can hit-test the submit button/checkbox without needing
// to scroll them into view first.
Future<void> _pumpSignup(WidgetTester tester, AuthCubit authCubit) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_wrap(authCubit));
}

Future<void> _fillValidForm(WidgetTester tester) async {
  final textFields = find.byType(TextField);
  await tester.enterText(textFields.at(0), 'Jane Doe');
  await tester.enterText(textFields.at(1), 'jane@example.com');
  await tester.enterText(textFields.at(2), 'Password1');
  await tester.enterText(textFields.at(3), 'Password1');
}

void main() {
  late MockAuthCubit authCubit;
  late MockAnalyticsService analyticsService;

  setUpAll(() {
    registerFallbackValue(const AuthState.initial());
  });

  setUp(() {
    authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(const AuthState.initial());
    whenListen(authCubit, const Stream<AuthState>.empty());
    when(
      () => authCubit.signUpWithEmail(
        fullName: any(named: 'fullName'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});

    analyticsService = MockAnalyticsService();
    when(
      () => analyticsService.logEvent(any(), any()),
    ).thenAnswer((_) async {});
    when(() => analyticsService.logEvent(any())).thenAnswer((_) async {});

    GetIt.I.allowReassignment = true;
    GetIt.I.registerSingleton<AnalyticsService>(analyticsService);
  });

  tearDown(() {
    if (GetIt.I.isRegistered<AnalyticsService>()) {
      GetIt.I.unregister<AnalyticsService>();
    }
    GetIt.I.allowReassignment = false;
  });

  group('SignupView — validation', () {
    testWidgets(
      'TC-signup-1: shows required errors when submitting empty form',
      (tester) async {
        await _pumpSignup(tester, authCubit);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(_submitButtonFinder);
        await tester.pumpAndSettle();

        expect(find.text('El nombre completo es requerido'), findsOneWidget);
        expect(find.text('El email es requerido'), findsOneWidget);
        expect(find.text('La contraseña es requerida'), findsOneWidget);
        expect(
          find.text('Por favor confirma tu contraseña'),
          findsOneWidget,
        );
        verifyNever(
          () => authCubit.signUpWithEmail(
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    testWidgets(
      'TC-signup-2: shows password rule errors (min length, uppercase, number)',
      (tester) async {
        await _pumpSignup(tester, authCubit);
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'Jane Doe');
        await tester.enterText(textFields.at(1), 'jane@example.com');
        await tester.enterText(textFields.at(2), 'abc');
        await tester.enterText(textFields.at(3), 'abc');
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(_submitButtonFinder);
        await tester.pumpAndSettle();

        expect(
          find.text('La contraseña debe tener al menos 8 caracteres'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TC-signup-3: shows mismatch error when confirm password differs',
      (tester) async {
        await _pumpSignup(tester, authCubit);
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'Jane Doe');
        await tester.enterText(textFields.at(1), 'jane@example.com');
        await tester.enterText(textFields.at(2), 'Password1');
        await tester.enterText(textFields.at(3), 'Password2');
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(_submitButtonFinder);
        await tester.pumpAndSettle();

        expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
        verifyNever(
          () => authCubit.signUpWithEmail(
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );
  });

  group('SignupView — terms & submit', () {
    testWidgets(
      'TC-signup-4: valid form without accepting terms shows SnackBar and '
      'does not call signUpWithEmail',
      (tester) async {
        await _pumpSignup(tester, authCubit);
        await tester.pumpAndSettle();

        await _fillValidForm(tester);

        await tester.tap(_submitButtonFinder);
        await tester.pumpAndSettle();

        expect(
          find.text('Por favor acepta los términos y condiciones'),
          findsOneWidget,
        );
        verifyNever(
          () => authCubit.signUpWithEmail(
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    testWidgets(
      'TC-signup-5: valid form with terms accepted calls signUpWithEmail '
      'with trimmed values',
      (tester) async {
        await _pumpSignup(tester, authCubit);
        await tester.pumpAndSettle();

        await _fillValidForm(tester);
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(_submitButtonFinder);
        await tester.pump();

        verify(
          () => authCubit.signUpWithEmail(
            fullName: 'Jane Doe',
            email: 'jane@example.com',
            password: 'Password1',
          ),
        ).called(1);
      },
    );

    testWidgets(
      'TC-signup-6: error state shows SnackBar with the error message',
      (tester) async {
        whenListen(
          authCubit,
          Stream.fromIterable([
            const AuthState.loading(),
            const AuthState.error('Email ya registrado'),
          ]),
        );
        when(
          () => authCubit.state,
        ).thenReturn(const AuthState.error('Email ya registrado'));

        await _pumpSignup(tester, authCubit);
        await tester.pumpAndSettle();

        expect(find.text('Email ya registrado'), findsOneWidget);
      },
    );
  });
}
