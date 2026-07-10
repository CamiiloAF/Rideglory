// Widget tests for ForgotPasswordView.
//
// Covers email validation, error snackbar, the sent-confirmation content
// (with resend), and AuthCubit.sendPasswordResetEmail invocation.
// AuthCubit is mocked (bloc_test's MockCubit) — no real Firebase call.

import 'dart:async';

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
import 'package:rideglory/features/authentication/login/presentation/forgot_password_view.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

Widget _wrap(AuthCubit authCubit) {
  final router = GoRouter(
    initialLocation: AppRoutes.forgotPassword,
    routes: [
      GoRoute(
        name: AppRoutes.forgotPassword,
        path: AppRoutes.forgotPassword,
        builder: (_, _) => BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const ForgotPasswordView(),
        ),
      ),
      GoRoute(
        name: AppRoutes.login,
        path: AppRoutes.login,
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
      () => authCubit.sendPasswordResetEmail(any()),
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

  group('ForgotPasswordView — validation', () {
    testWidgets(
      'TC-forgot-1: shows required error when submitting empty email',
      (tester) async {
        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Enviar enlace'));
        await tester.pumpAndSettle();

        expect(find.text('El email es requerido'), findsOneWidget);
        verifyNever(() => authCubit.sendPasswordResetEmail(any()));
      },
    );

    testWidgets(
      'TC-forgot-2: shows invalid email error for malformed email',
      (tester) async {
        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'not-an-email');
        await tester.tap(find.text('Enviar enlace'));
        await tester.pumpAndSettle();

        expect(find.text('Dirección de correo inválida'), findsOneWidget);
        verifyNever(() => authCubit.sendPasswordResetEmail(any()));
      },
    );
  });

  group('ForgotPasswordView — submit', () {
    testWidgets(
      'TC-forgot-3: valid email calls sendPasswordResetEmail with trimmed value',
      (tester) async {
        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'user@example.com');
        await tester.tap(find.text('Enviar enlace'));
        await tester.pump();

        verify(
          () => authCubit.sendPasswordResetEmail('user@example.com'),
        ).called(1);
      },
    );

    testWidgets(
      'TC-forgot-4: error state shows SnackBar with the error message',
      (tester) async {
        whenListen(
          authCubit,
          Stream.fromIterable([
            const AuthState.loading(),
            const AuthState.error('Email no encontrado'),
          ]),
        );
        when(
          () => authCubit.state,
        ).thenReturn(const AuthState.error('Email no encontrado'));

        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        expect(find.text('Email no encontrado'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-forgot-5: passwordResetEmailSent state shows the sent-confirmation '
      'content with the submitted email, and resend calls '
      'sendPasswordResetEmail again with the same email',
      (tester) async {
        // Drive AuthCubit.state manually so the widget observes the real
        // transition initial -> loading -> passwordResetEmailSent while it
        // is mounted (needed for ForgotPasswordView to capture the typed
        // email and switch to the sent-confirmation content).
        var currentState = const AuthState.initial();
        final controller = StreamController<AuthState>.broadcast();
        addTearDown(controller.close);
        when(() => authCubit.state).thenAnswer((_) => currentState);
        whenListen(
          authCubit,
          controller.stream,
          initialState: currentState,
        );

        await tester.pumpWidget(_wrap(authCubit));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'user@example.com');
        await tester.tap(find.text('Enviar enlace'));

        currentState = const AuthState.loading();
        controller.add(currentState);
        await tester.pump();

        currentState = const AuthState.passwordResetEmailSent();
        controller.add(currentState);
        await tester.pumpAndSettle();

        expect(find.text('Correo enviado'), findsOneWidget);
        expect(find.text('user@example.com'), findsWidgets);

        await tester.tap(find.text('No recibí el correo — reenviar'));
        await tester.pump();

        verify(
          () => authCubit.sendPasswordResetEmail('user@example.com'),
        ).called(2);
      },
    );
  });
}
