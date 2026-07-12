/// Cubre el comportamiento de [FirebaseAuthInterceptor] ante un 401:
///
/// - Refresh de token exitoso → reintento normal, sin logout ni snackbar.
/// - Refresh que lanza [FirebaseAuthException] con un código de sesión
///   invalidada (`user-not-found`, `user-disabled`, `user-token-expired`)
///   → logout forzado vía [AuthCubit.signOut] + snackbar, error original
///   propagado.
/// - Refresh que lanza `network-request-failed` (código transitorio de
///   conectividad) → nunca logout, error original propagado.
library;

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/http/firebase_auth_interceptor.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_router.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockAuthCubit extends Mock implements AuthCubit {}

/// Widget mínimo que ancla [AppRouter.scaffoldMessengerKey], igual que en la
/// app real, para poder verificar el snackbar mostrado por el interceptor.
class _ScaffoldMessengerHost extends StatelessWidget {
  const _ScaffoldMessengerHost();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      scaffoldMessengerKey: AppRouter.scaffoldMessengerKey,
      home: const Scaffold(body: SizedBox.shrink()),
    );
  }
}

void main() {
  late _MockFirebaseAuth firebaseAuth;
  late _MockUser user;
  late _MockAuthCubit authCubit;
  late FirebaseAuthInterceptor interceptor;

  DioException unauthorizedError() {
    // Puerto local sin listener + timeout corto: el reintento real que hace
    // el interceptor falla rápido (sin depender de red externa/DNS ni
    // colgar el test en un sandbox sin salida a internet).
    final options = RequestOptions(
      path: 'http://127.0.0.1:9/me',
      connectTimeout: const Duration(milliseconds: 200),
      sendTimeout: const Duration(milliseconds: 200),
      receiveTimeout: const Duration(milliseconds: 200),
    );
    return DioException(
      requestOptions: options,
      response: Response<void>(requestOptions: options, statusCode: 401),
      type: DioExceptionType.badResponse,
    );
  }

  /// Espera el resultado de [handler] y devuelve el [DioException] que
  /// `handler.next(err)` propagó. `_BaseHandler.future` rechaza con un
  /// `InterceptorState<DioException>` (tipo interno, no exportado por
  /// `dio`) que envuelve el error original en su campo `.data`.
  Future<DioException> awaitPropagatedError(
    ErrorInterceptorHandler handler,
  ) async {
    try {
      // ignore: invalid_use_of_protected_member
      await handler.future;
    } catch (error) {
      final dynamic state = error;
      return state.data as DioException;
    }
    fail('Se esperaba que el handler propagara un error, pero se resolvió.');
  }

  setUp(() {
    firebaseAuth = _MockFirebaseAuth();
    user = _MockUser();
    authCubit = _MockAuthCubit();
    interceptor = FirebaseAuthInterceptor(firebaseAuth);

    when(() => firebaseAuth.currentUser).thenReturn(user);
    when(() => authCubit.signOut()).thenAnswer((_) async {});

    if (GetIt.instance.isRegistered<AuthCubit>()) {
      GetIt.instance.unregister<AuthCubit>();
    }
    GetIt.instance.registerSingleton<AuthCubit>(authCubit);
  });

  tearDown(() {
    if (GetIt.instance.isRegistered<AuthCubit>()) {
      GetIt.instance.unregister<AuthCubit>();
    }
  });

  group('FirebaseAuthInterceptor.onError — 401', () {
    testWidgets(
      'refresh exitoso (sin FirebaseAuthException) → nunca logout ni snackbar',
      (tester) async {
        await tester.pumpWidget(const _ScaffoldMessengerHost());
        await tester.pumpAndSettle();

        // No devuelve un token fresco (`null`): el interceptor no entra al
        // camino de reintento (que abriría un socket real), pero tampoco
        // lanza FirebaseAuthException — es el camino "no hubo error de
        // sesión invalidada", que es lo relevante para esta prueba.
        when(() => user.getIdToken(true)).thenAnswer((_) async => null);

        final handler = ErrorInterceptorHandler();
        final originalError = unauthorizedError();
        interceptor.onError(originalError, handler);

        final propagated = await awaitPropagatedError(handler);

        await tester.pumpAndSettle();

        expect(propagated, same(originalError));
        verifyNever(() => authCubit.signOut());
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets(
      'refresh falla con user-not-found → signOut + snackbar, error propagado',
      (tester) async {
        await tester.pumpWidget(const _ScaffoldMessengerHost());
        await tester.pumpAndSettle();

        when(() => user.getIdToken(true)).thenThrow(
          FirebaseAuthException(code: 'user-not-found'),
        );

        final handler = ErrorInterceptorHandler();
        final originalError = unauthorizedError();
        interceptor.onError(originalError, handler);

        final propagated = await awaitPropagatedError(handler);

        await tester.pumpAndSettle();

        expect(propagated, same(originalError));
        verify(() => authCubit.signOut()).called(1);
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets(
      'refresh falla con user-disabled → signOut + snackbar',
      (tester) async {
        await tester.pumpWidget(const _ScaffoldMessengerHost());
        await tester.pumpAndSettle();

        when(
          () => user.getIdToken(true),
        ).thenThrow(FirebaseAuthException(code: 'user-disabled'));

        final handler = ErrorInterceptorHandler();
        interceptor.onError(unauthorizedError(), handler);

        await awaitPropagatedError(handler);
        await tester.pumpAndSettle();

        verify(() => authCubit.signOut()).called(1);
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets(
      'refresh falla con user-token-expired → signOut + snackbar',
      (tester) async {
        await tester.pumpWidget(const _ScaffoldMessengerHost());
        await tester.pumpAndSettle();

        when(
          () => user.getIdToken(true),
        ).thenThrow(FirebaseAuthException(code: 'user-token-expired'));

        final handler = ErrorInterceptorHandler();
        interceptor.onError(unauthorizedError(), handler);

        await awaitPropagatedError(handler);
        await tester.pumpAndSettle();

        verify(() => authCubit.signOut()).called(1);
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets(
      'refresh falla con network-request-failed → nunca logout',
      (tester) async {
        await tester.pumpWidget(const _ScaffoldMessengerHost());
        await tester.pumpAndSettle();

        when(
          () => user.getIdToken(true),
        ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

        final handler = ErrorInterceptorHandler();
        final originalError = unauthorizedError();
        interceptor.onError(originalError, handler);

        final propagated = await awaitPropagatedError(handler);

        await tester.pumpAndSettle();

        expect(propagated, same(originalError));
        verifyNever(() => authCubit.signOut());
        expect(find.byType(SnackBar), findsNothing);
      },
    );
  });
}
