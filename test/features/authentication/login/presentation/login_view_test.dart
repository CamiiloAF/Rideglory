// Widget tests for LoginView.
//
// Covers form validation, error snackbar on failed sign-in, and the happy
// path invoking AuthCubit.signInWithEmail with the trimmed form values.
// AuthCubit is mocked (bloc_test's MockCubit) — no real Firebase/service call.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/authentication/login/presentation/login_view.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

Widget _wrap(AuthCubit authCubit) {
  final router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        name: AppRoutes.login,
        path: AppRoutes.login,
        builder: (_, _) => BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const LoginView(),
        ),
      ),
      GoRoute(
        name: AppRoutes.signup,
        path: AppRoutes.signup,
        builder: (_, _) => const Scaffold(body: SizedBox()),
      ),
      GoRoute(
        name: AppRoutes.forgotPassword,
        path: AppRoutes.forgotPassword,
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
      () => authCubit.signInWithEmail(
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

  group('LoginView — validation', () {
    testWidgets(
      'TC-login-1: shows required errors when submitting empty form',
      (tester) async {
        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();

        expect(find.text('El email es requerido'), findsOneWidget);
        expect(find.text('La contraseña es requerida'), findsOneWidget);
        verifyNever(
          () => authCubit.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    testWidgets('TC-login-2: shows invalid email error for malformed email', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(authCubit));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'not-an-email');
      await tester.enterText(textFields.at(1), 'password123');

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Dirección de correo inválida'), findsOneWidget);
      verifyNever(
        () => authCubit.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets(
      'TC-login-3: shows min length error for short password',
      (tester) async {
        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'user@example.com');
        await tester.enterText(textFields.at(1), '123');

        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();

        expect(
          find.text('La contraseña debe tener al menos 6 caracteres'),
          findsOneWidget,
        );
      },
    );
  });

  group('LoginView — submit', () {
    testWidgets(
      'TC-login-4: valid form calls signInWithEmail with trimmed values',
      (tester) async {
        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'user@example.com');
        await tester.enterText(textFields.at(1), 'password123');

        await tester.tap(find.text('Iniciar sesión'));
        await tester.pump();

        verify(
          () => authCubit.signInWithEmail(
            email: 'user@example.com',
            password: 'password123',
          ),
        ).called(1);
      },
    );

    testWidgets(
      'TC-login-4b: button shows loading state while sign-in is in progress',
      (tester) async {
        final controller = StreamController<AuthState>();
        addTearDown(controller.close);
        whenListen(authCubit, controller.stream);

        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'user@example.com');
        await tester.enterText(textFields.at(1), 'password123');

        // Before submitting, the button is idle (no spinner).
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.tap(find.text('Iniciar sesión'));
        await tester.pump();

        // `_emailLoading` flips to true synchronously on submit, before the
        // cubit resolves — the button must already show its loading state.
        final loadingButton = tester.widget<AppButton>(
          find.byType(AppButton),
        );
        expect(loadingButton.isLoading, isTrue);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        controller.add(const AuthState.loading());
        await tester.pump();
        expect(
          tester.widget<AppButton>(find.byType(AppButton)).isLoading,
          isTrue,
        );

        controller.add(const AuthState.error('Credenciales inválidas'));
        await tester.pump();

        final settledButton = tester.widget<AppButton>(
          find.byType(AppButton),
        );
        expect(settledButton.isLoading, isFalse);
      },
    );

    testWidgets(
      'TC-login-5: error state shows SnackBar with the error message',
      (tester) async {
        whenListen(
          authCubit,
          Stream.fromIterable([
            const AuthState.loading(),
            const AuthState.error('Credenciales inválidas'),
          ]),
        );
        when(() => authCubit.state).thenReturn(
          const AuthState.error('Credenciales inválidas'),
        );

        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        expect(find.text('Credenciales inválidas'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-login-6: tapping "¿Olvidaste tu contraseña?" navigates to forgot-password',
      (tester) async {
        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        await tester.tap(find.text('¿Olvidaste tu contraseña?'));
        await tester.pumpAndSettle();

        expect(find.byType(LoginView), findsNothing);
      },
    );
  });

  group('LoginView — exit confirmation dialog', () {
    // The Android system back gesture/button is simulated by dispatching the
    // same platform message the engine sends for a real back press
    // ('flutter/navigation' -> 'popRoute'), which is what reaches the root
    // PopScope in LoginView (canPop: false).
    Future<void> simulateSystemBack(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    testWidgets(
      'TC-login-7: system back button shows the exit confirmation dialog '
      'and does not pop the screen',
      (tester) async {
        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        await simulateSystemBack(tester);

        expect(find.text('Salir del inicio de sesión'), findsOneWidget);
        expect(
          find.text('¿Estás seguro de que deseas salir?'),
          findsOneWidget,
        );
        // The screen itself is still there, underneath the dialog.
        expect(find.byType(LoginView), findsOneWidget);
      },
    );

    testWidgets(
      'TC-login-8: confirming the exit dialog calls SystemNavigator.pop',
      (tester) async {
        var systemNavigatorPopCalled = false;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (methodCall) async {
            if (methodCall.method == 'SystemNavigator.pop') {
              systemNavigatorPopCalled = true;
            }
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });

        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        await simulateSystemBack(tester);
        expect(find.text('Salir del inicio de sesión'), findsOneWidget);

        await tester.tap(find.text('Confirmar'));
        await tester.pumpAndSettle();

        expect(systemNavigatorPopCalled, isTrue);
      },
    );
  });
}
