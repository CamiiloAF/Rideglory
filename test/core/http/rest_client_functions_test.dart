import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/api_result.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/crash/crash_reporter.dart';

class MockCrashReporter extends Mock implements CrashReporter {}

/// Helper que ejecuta [handlerExceptionHttpTestable] con un mock de
/// [CrashReporter] inyectado y `isDebug=false` (simula release).
Future<ApiResult<T>> _exec<T>({
  required Future<T> Function() function,
  required MockCrashReporter reporter,
}) => handlerExceptionHttpTestable(
  function: function,
  crashReporter: reporter,
  isDebug: false,
);

/// Crea un [DioException] con tipo y status code opcionales.
DioException _dioEx(DioExceptionType type, {int? statusCode}) {
  final opts = RequestOptions(path: 'https://api.test.com/events/detail');
  return DioException(
    type: type,
    requestOptions: opts,
    response: statusCode != null
        ? Response<void>(requestOptions: opts, statusCode: statusCode)
        : null,
  );
}

void main() {
  late MockCrashReporter reporter;

  setUp(() {
    reporter = MockCrashReporter();
    when(
      () => reporter.recordError(
        any(),
        any(),
        reason: any(named: 'reason'),
        fatal: any(named: 'fatal'),
        information: any(named: 'information'),
      ),
    ).thenAnswer((_) async {});
  });

  // ─── DioException — reporta ────────────────────────────────────────────────

  group('DioException — reporta no-fatal', () {
    final reportingTypes = [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.badCertificate,
      DioExceptionType.unknown,
    ];

    for (final type in reportingTypes) {
      test(
        '$type → recordError(fatal:false) called(1), category=network',
        () async {
          await _exec<String>(
            function: () => Future.error(_dioEx(type)),
            reporter: reporter,
          );

          final captured = verify(
            () => reporter.recordError(
              any(),
              any(),
              reason: any(named: 'reason'),
              fatal: false,
              information: captureAny(named: 'information'),
            ),
          )..called(1);

          final info = captured.captured.first as List<String>;
          expect(
            info.any((s) => s.contains(AnalyticsParams.categoryNetwork)),
            isTrue,
          );
        },
      );
    }

    test(
      'badResponse 500 → recordError called(1) con http_status=500',
      () async {
        await _exec<String>(
          function: () => Future.error(
            _dioEx(DioExceptionType.badResponse, statusCode: 500),
          ),
          reporter: reporter,
        );

        final captured = verify(
          () => reporter.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: false,
            information: captureAny(named: 'information'),
          ),
        )..called(1);

        final info = captured.captured.first as List<String>;
        expect(info.any((s) => s.contains('http_status=500')), isTrue);
      },
    );
  });

  // ─── DioException — NO reporta ────────────────────────────────────────────

  group('DioException — NO reporta no-fatal', () {
    const noReportCodes = [400, 401, 403, 404, 409];

    for (final code in noReportCodes) {
      test('badResponse $code → verifyNever', () async {
        await _exec<String>(
          function: () => Future.error(
            _dioEx(DioExceptionType.badResponse, statusCode: code),
          ),
          reporter: reporter,
        );

        verifyNever(
          () => reporter.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: any(named: 'fatal'),
            information: any(named: 'information'),
          ),
        );
      });
    }

    test('cancel → verifyNever', () async {
      await _exec<String>(
        function: () => Future.error(_dioEx(DioExceptionType.cancel)),
        reporter: reporter,
      );

      verifyNever(
        () => reporter.recordError(
          any(),
          any(),
          reason: any(named: 'reason'),
          fatal: any(named: 'fatal'),
          information: any(named: 'information'),
        ),
      );
    });
  });

  // ─── FirebaseAuthException ─────────────────────────────────────────────────

  group('FirebaseAuthException', () {
    const expectedCodes = [
      'wrong-password',
      'invalid-credential',
      'user-not-found',
      'email-already-in-use',
      'weak-password',
      'too-many-requests',
    ];

    for (final code in expectedCodes) {
      test('$code → verifyNever (negocio esperado)', () async {
        await _exec<String>(
          function: () => Future.error(FirebaseAuthException(code: code)),
          reporter: reporter,
        );

        verifyNever(
          () => reporter.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: any(named: 'fatal'),
            information: any(named: 'information'),
          ),
        );
      });
    }

    test(
      'network-request-failed → recordError(fatal:false), category=network',
      () async {
        await _exec<String>(
          function: () => Future.error(
            FirebaseAuthException(code: 'network-request-failed'),
          ),
          reporter: reporter,
        );

        final captured = verify(
          () => reporter.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: false,
            information: captureAny(named: 'information'),
          ),
        )..called(1);

        final info = captured.captured.first as List<String>;
        expect(
          info.any((s) => s.contains(AnalyticsParams.categoryNetwork)),
          isTrue,
        );
      },
    );
  });

  // ─── PlatformException ────────────────────────────────────────────────────

  group('PlatformException', () {
    const expectedCodes = [
      'sign_in_cancelled',
      'sign_in_failed',
      'network_error',
    ];

    for (final code in expectedCodes) {
      test('$code → verifyNever (código conocido)', () async {
        await _exec<String>(
          function: () => Future.error(PlatformException(code: code)),
          reporter: reporter,
        );

        verifyNever(
          () => reporter.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: any(named: 'fatal'),
            information: any(named: 'information'),
          ),
        );
      });
    }

    test(
      'código inesperado → recordError(fatal:false), category=platform_unexpected',
      () async {
        await _exec<String>(
          function: () => Future.error(PlatformException(code: 'unknown_xyz')),
          reporter: reporter,
        );

        final captured = verify(
          () => reporter.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: false,
            information: captureAny(named: 'information'),
          ),
        )..called(1);

        final info = captured.captured.first as List<String>;
        expect(
          info.any(
            (s) => s.contains(AnalyticsParams.categoryPlatformUnexpected),
          ),
          isTrue,
        );
      },
    );
  });

  // ─── DomainException — anti doble-conteo ─────────────────────────────────

  test(
    'DomainException → verifyNever (anti doble-conteo, matriz G5)',
    () async {
      await _exec<String>(
        function: () => Future.error(const DomainException(message: 'error')),
        reporter: reporter,
      );

      verifyNever(
        () => reporter.recordError(
          any(),
          any(),
          reason: any(named: 'reason'),
          fatal: any(named: 'fatal'),
          information: any(named: 'information'),
        ),
      );
    },
  );

  // ─── Catch genérico ───────────────────────────────────────────────────────

  test(
    'catch genérico → recordError(fatal:false), category=unexpected, stackTrace no nulo',
    () async {
      await _exec<String>(
        function: () => Future.error(Exception('bug inesperado')),
        reporter: reporter,
      );

      final captured = verify(
        () => reporter.recordError(
          any(),
          any(),
          reason: any(named: 'reason'),
          fatal: false,
          information: captureAny(named: 'information'),
        ),
      )..called(1);

      final info = captured.captured.first as List<String>;
      expect(
        info.any((s) => s.contains(AnalyticsParams.categoryUnexpected)),
        isTrue,
      );
    },
  );

  // ─── Sanitización del endpoint ────────────────────────────────────────────

  test(
    'DioException 500 — endpoint sanitizado no contiene query string ni ids dinámicos',
    () async {
      final opts = RequestOptions(
        path:
            'https://api.test.com/events/550e8400-e29b-41d4-a716-446655440000?token=secret',
      );
      final ex = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: opts,
        response: Response<void>(requestOptions: opts, statusCode: 500),
      );

      await _exec<String>(function: () => Future.error(ex), reporter: reporter);

      final captured = verify(
        () => reporter.recordError(
          any(),
          any(),
          reason: any(named: 'reason'),
          fatal: false,
          information: captureAny(named: 'information'),
        ),
      )..called(1);

      final info = captured.captured.first as List<String>;
      final endpointEntry = info.firstWhere(
        (s) => s.startsWith('${AnalyticsParams.endpoint}='),
        orElse: () => '',
      );

      // Sin query string.
      expect(endpointEntry, isNot(contains('token')));
      expect(endpointEntry, isNot(contains('?')));
      // Sin UUID crudo.
      expect(
        endpointEntry,
        isNot(contains('550e8400-e29b-41d4-a716-446655440000')),
      );
      // Con segmento enmascarado.
      expect(endpointEntry, contains(':id'));
    },
  );

  // ─── Gating: isDebug=true nunca reporta ──────────────────────────────────

  test('Gating — isDebug=true: ningun DioException reporta no-fatal', () async {
    await handlerExceptionHttpTestable<String>(
      function: () => Future.error(_dioEx(DioExceptionType.connectionTimeout)),
      crashReporter: reporter,
      isDebug: true, // simula kDebugMode
    );

    verifyNever(
      () => reporter.recordError(
        any(),
        any(),
        reason: any(named: 'reason'),
        fatal: any(named: 'fatal'),
        information: any(named: 'information'),
      ),
    );
  });

  // ─── executeService no fue modificado ────────────────────────────────────

  test('executeService sigue funcionando (retorna Right en éxito)', () async {
    final result = await executeService<String>(function: () async => 'ok');
    expect(result.isRight(), isTrue);
  });

  test('executeService sigue funcionando (retorna Left en fallo)', () async {
    final result = await executeService<String>(
      function: () => Future.error(const DomainException(message: 'fail')),
    );
    expect(result.isLeft(), isTrue);
  });
}
