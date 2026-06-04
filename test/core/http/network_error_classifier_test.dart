import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/core/http/network_error_classifier.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';

/// Helper que crea un [DioException] con el tipo y código de estado dados.
DioException _dioException(
  DioExceptionType type, {
  int? statusCode,
}) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    type: type,
    requestOptions: requestOptions,
    response: statusCode != null
        ? Response<void>(
            requestOptions: requestOptions,
            statusCode: statusCode,
          )
        : null,
  );
}

/// Helper que crea un [FirebaseAuthException] con el código dado.
FirebaseAuthException _firebaseException(String code) =>
    FirebaseAuthException(code: code);

void main() {
  group('classifyDioException', () {
    test('connectionTimeout → shouldReport=true, category=network, reason=network_timeout',
        () {
      final ex = _dioException(DioExceptionType.connectionTimeout);
      final result = classifyDioException(ex);
      expect(result.shouldReport, isTrue);
      expect(result.category, equals(AnalyticsParams.categoryNetwork));
      expect(result.reason, equals(AnalyticsParams.reasonNetworkTimeout));
    });

    test('sendTimeout → shouldReport=true, reason=network_timeout', () {
      final ex = _dioException(DioExceptionType.sendTimeout);
      final result = classifyDioException(ex);
      expect(result.shouldReport, isTrue);
      expect(result.reason, equals(AnalyticsParams.reasonNetworkTimeout));
    });

    test('receiveTimeout → shouldReport=true, reason=network_timeout', () {
      final ex = _dioException(DioExceptionType.receiveTimeout);
      final result = classifyDioException(ex);
      expect(result.shouldReport, isTrue);
      expect(result.reason, equals(AnalyticsParams.reasonNetworkTimeout));
    });

    test('connectionError → shouldReport=true, reason=network_connection', () {
      final ex = _dioException(DioExceptionType.connectionError);
      final result = classifyDioException(ex);
      expect(result.shouldReport, isTrue);
      expect(result.reason, equals(AnalyticsParams.reasonNetworkConnection));
    });

    test('badCertificate → shouldReport=true, reason=network_connection', () {
      final ex = _dioException(DioExceptionType.badCertificate);
      final result = classifyDioException(ex);
      expect(result.shouldReport, isTrue);
      expect(result.reason, equals(AnalyticsParams.reasonNetworkConnection));
    });

    test('badResponse 500 → shouldReport=true, reason=network_5xx, httpStatus=500', () {
      final ex = _dioException(DioExceptionType.badResponse, statusCode: 500);
      final result = classifyDioException(ex);
      expect(result.shouldReport, isTrue);
      expect(result.reason, equals(AnalyticsParams.reasonNetwork5xx));
      expect(result.httpStatus, equals(500));
    });

    test('badResponse 503 → shouldReport=true, reason=network_5xx', () {
      final ex = _dioException(DioExceptionType.badResponse, statusCode: 503);
      final result = classifyDioException(ex);
      expect(result.shouldReport, isTrue);
    });

    test('badResponse 400 → shouldReport=false (negocio esperado)', () {
      final ex = _dioException(DioExceptionType.badResponse, statusCode: 400);
      final result = classifyDioException(ex);
      expect(result.shouldReport, isFalse);
    });

    test('badResponse 401 → shouldReport=false', () {
      final ex = _dioException(DioExceptionType.badResponse, statusCode: 401);
      expect(classifyDioException(ex).shouldReport, isFalse);
    });

    test('badResponse 403 → shouldReport=false', () {
      final ex = _dioException(DioExceptionType.badResponse, statusCode: 403);
      expect(classifyDioException(ex).shouldReport, isFalse);
    });

    test('badResponse 404 → shouldReport=false', () {
      final ex = _dioException(DioExceptionType.badResponse, statusCode: 404);
      expect(classifyDioException(ex).shouldReport, isFalse);
    });

    test('badResponse 409 → shouldReport=false', () {
      final ex = _dioException(DioExceptionType.badResponse, statusCode: 409);
      expect(classifyDioException(ex).shouldReport, isFalse);
    });

    test('cancel → shouldReport=false', () {
      final ex = _dioException(DioExceptionType.cancel);
      expect(classifyDioException(ex).shouldReport, isFalse);
    });

    test('unknown → shouldReport=true', () {
      final ex = _dioException(DioExceptionType.unknown);
      expect(classifyDioException(ex).shouldReport, isTrue);
    });
  });

  group('classifyFirebaseAuthException', () {
    const expectedCodes = [
      'wrong-password',
      'user-not-found',
      'invalid-credential',
      'invalid-email',
      'email-already-in-use',
      'weak-password',
      'too-many-requests',
      'user-disabled',
      'operation-not-allowed',
      'credential-already-in-use',
      'requires-recent-login',
    ];

    for (final code in expectedCodes) {
      test('$code → shouldReport=false (error de negocio esperado)', () {
        final ex = _firebaseException(code);
        expect(classifyFirebaseAuthException(ex).shouldReport, isFalse);
      });
    }

    test('network-request-failed → shouldReport=true, category=network', () {
      final ex = _firebaseException('network-request-failed');
      final result = classifyFirebaseAuthException(ex);
      expect(result.shouldReport, isTrue);
      expect(result.category, equals(AnalyticsParams.categoryNetwork));
      expect(result.reason, equals(AnalyticsParams.reasonFirebaseNetwork));
    });
  });

  group('classifyPlatformException', () {
    const expectedCodes = ['sign_in_cancelled', 'sign_in_failed', 'network_error'];

    for (final code in expectedCodes) {
      test('$code → shouldReport=false (código esperado de sign-in)', () {
        final ex = PlatformException(code: code);
        expect(classifyPlatformException(ex).shouldReport, isFalse);
      });
    }

    test('código inesperado → shouldReport=true, category=platform_unexpected', () {
      final ex = PlatformException(code: 'unknown_xyz_unexpected');
      final result = classifyPlatformException(ex);
      expect(result.shouldReport, isTrue);
      expect(result.category, equals(AnalyticsParams.categoryPlatformUnexpected));
      expect(result.reason, equals(AnalyticsParams.reasonPlatformUnexpected));
    });
  });

  group('sanitizeEndpoint', () {
    test('null URL → unknown', () {
      expect(sanitizeEndpoint(null), equals('unknown'));
    });

    test('URL vacía → unknown', () {
      expect(sanitizeEndpoint(''), equals('unknown'));
    });

    test('elimina query string', () {
      final result = sanitizeEndpoint('https://api.example.com/events?id=123');
      expect(result, isNot(contains('?')));
      expect(result, isNot(contains('123')));
    });

    test('enmascara segmentos numéricos', () {
      final result = sanitizeEndpoint('https://api.example.com/users/42/profile');
      expect(result, contains(':id'));
      expect(result, isNot(contains('/42')));
    });

    test('enmascara UUIDs', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final result = sanitizeEndpoint('https://api.example.com/events/$uuid');
      expect(result, contains(':id'));
      expect(result, isNot(contains(uuid)));
    });

    test('mantiene segmentos de texto estables', () {
      final result = sanitizeEndpoint('https://api.example.com/events/detail');
      expect(result, contains('events'));
      expect(result, contains('detail'));
    });

    test('elimina fragmento (#)', () {
      final result = sanitizeEndpoint('https://api.example.com/path#section');
      expect(result, isNot(contains('#')));
    });

    test('resultado truncado a 100 chars máximo', () {
      final longPath = List.generate(50, (_) => 'segment').join('/');
      final url = 'https://api.example.com/$longPath';
      final result = sanitizeEndpoint(url);
      expect(result.length, lessThanOrEqualTo(100));
    });
  });
}
