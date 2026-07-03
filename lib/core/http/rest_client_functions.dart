import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:get_it/get_it.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/crash/crash_reporter.dart';

import '../exceptions/domain_exception.dart';
import 'api_result.dart';
import 'network_error_classifier.dart';

const _genericErrorMessage =
    'Ups, tuvimos un error interno, por favor intentalo de nuevo más tarde.';

/// Obtiene el [CrashReporter] del contenedor DI de forma defensiva.
///
/// Devuelve `null` si el contenedor aún no está listo (p.ej. en tests sin
/// DI configurado). El reporte de no-fatales nunca debe propagar excepciones
/// a la capa HTTP.
CrashReporter? _crashReporter() {
  try {
    return GetIt.instance<CrashReporter>();
  } catch (_) {
    return null;
  }
}

/// Construye la lista de información no-PII para el reporte de no-fatales.
List<String> _buildInformation({
  required String category,
  int? httpStatus,
  String? dioType,
  String? endpointUrl,
}) {
  return [
    '${AnalyticsParams.errorCategory}=$category',
    if (httpStatus != null) '${AnalyticsParams.httpStatus}=$httpStatus',
    if (dioType != null) '${AnalyticsParams.dioType}=$dioType',
    if (endpointUrl != null)
      '${AnalyticsParams.endpoint}=${sanitizeEndpoint(endpointUrl)}',
  ];
}

/// Ejecuta [function] y mapea todas las excepciones a [ApiResult].
///
/// Este es el **único punto** donde pasan todas las llamadas HTTP. Los cubits
/// **no** re-reportan errores de red (ver matriz G5 en la Fase 4).
///
/// [crashReporterOverride] — solo para tests: inyecta un mock en lugar del
/// lookup DI. Permite verificar las llamadas a [CrashReporter] sin necesitar
/// DI configurado ni cambiar `kDebugMode`.
///
/// [isDebugOverride] — solo para tests: sobreescribe `kDebugMode` para poder
/// ejercer las ramas de reporte en un entorno de pruebas.
@visibleForTesting
Future<ApiResult<T>> handlerExceptionHttpTestable<T>({
  required Future<T> Function() function,
  required CrashReporter? crashReporter,
  required bool isDebug,
}) async {
  try {
    final apiResult = await function();
    return ApiResult.success(data: apiResult);
  } on DioException catch (dioException) {
    if (isDebug) {
      log('Error in DioException type: ${dioException.type}');
      log('Error in DioException message: ${dioException.message}');
      log('Error in DioException response: ${dioException.response?.data}');
    }

    // Fase 4 — reporte de no-fatales (solo en release).
    if (!isDebug) {
      final classification = classifyDioException(dioException);
      if (classification.shouldReport) {
        final reporter = crashReporter;
        if (reporter != null) {
          final info = _buildInformation(
            category: classification.category!,
            httpStatus: classification.httpStatus,
            dioType: classification.dioType,
            endpointUrl: dioException.requestOptions.uri.toString(),
          );
          try {
            await reporter.recordError(
              dioException,
              dioException.stackTrace,
              reason: classification.reason,
              fatal: false,
              information: info,
            );
          } catch (_) {
            // El reporte no debe romper el flujo HTTP.
          }
        }
      }
    }

    return ApiResult.failure(
      dataException: DomainException(
        message: _getDioErrorMessage(dioException),
      ),
    );
  } on FirebaseAuthException catch (firebaseException) {
    if (isDebug) {
      log('Error in FirebaseAuth code: ${firebaseException.code}');
      log('Error in FirebaseAuth message: ${firebaseException.message}');
      log('Error in FirebaseAuth stackTrace: ${firebaseException.stackTrace}');
    }

    // Fase 4 — reporte de no-fatales (solo en release).
    if (!isDebug) {
      final classification = classifyFirebaseAuthException(firebaseException);
      if (classification.shouldReport) {
        final reporter = crashReporter;
        if (reporter != null) {
          final info = _buildInformation(category: classification.category!);
          try {
            await reporter.recordError(
              firebaseException,
              firebaseException.stackTrace,
              reason: classification.reason,
              fatal: false,
              information: info,
            );
          } catch (_) {
            // El reporte no debe romper el flujo HTTP.
          }
        }
      }
    }

    return ApiResult.failure(
      dataException: DomainException(
        message: _getFirebaseAuthErrorMessage(firebaseException.code),
      ),
    );
  } on PlatformException catch (platformException) {
    if (isDebug) {
      log('Error in PlatformException code: ${platformException.code}');
      log('Error in PlatformException message: ${platformException.message}');
      log('Error in PlatformException details: ${platformException.details}');
    }

    // Fase 4 — reporte de no-fatales (solo en release).
    if (!isDebug) {
      final classification = classifyPlatformException(platformException);
      if (classification.shouldReport) {
        final reporter = crashReporter;
        if (reporter != null) {
          final info = _buildInformation(category: classification.category!);
          try {
            await reporter.recordError(
              platformException,
              platformException.stacktrace != null
                  ? StackTrace.fromString(platformException.stacktrace!)
                  : StackTrace.current,
              reason: classification.reason,
              fatal: false,
              information: info,
            );
          } catch (_) {
            // El reporte no debe romper el flujo HTTP.
          }
        }
      }
    }

    return ApiResult.failure(
      dataException: DomainException(
        message: _getPlatformExceptionErrorMessage(platformException.code),
      ),
    );
  } on SignInWithAppleAuthorizationException catch (e) {
    if (e.code == AuthorizationErrorCode.canceled) {
      return ApiResult.failure(
        dataException: const DomainException(
          message: 'Inicio de sesión cancelado.',
        ),
      );
    }
    if (!isDebug) {
      final reporter = crashReporter;
      if (reporter != null) {
        try {
          await reporter.recordError(
            e,
            StackTrace.current,
            reason: AnalyticsParams.categoryUnexpected,
            fatal: false,
            information: ['${AnalyticsParams.errorCategory}=apple_auth'],
          );
        } catch (_) {}
      }
    }
    return ApiResult.failure(
      dataException: const DomainException(
        message: 'Error al iniciar sesión con Apple.',
      ),
    );
  } on DomainException catch (domainException) {
    // Fase 4 — NO reportar: anti doble-conteo (ya fue evaluada en la rama
    // de origen). Ver matriz G5.
    return ApiResult.failure(dataException: domainException);
  } catch (error) {
    if (isDebug) {
      if (error is Error) {
        log('Stack trace: ${error.stackTrace}');
      }
      log('Error in Service Exception: $error}');
    }

    // Fase 4 — catch genérico: siempre reportar como no-fatal (bug real).
    if (!isDebug) {
      final reporter = crashReporter;
      if (reporter != null) {
        final stack = error is Error ? error.stackTrace : StackTrace.current;
        try {
          await reporter.recordError(
            error,
            stack,
            reason: AnalyticsParams.categoryUnexpected,
            fatal: false,
            information: [
              '${AnalyticsParams.errorCategory}=${AnalyticsParams.categoryUnexpected}',
            ],
          );
        } catch (_) {
          // El reporte no debe romper el flujo HTTP.
        }
      }
    }

    return ApiResult.failure(
      dataException: const DomainException(message: _genericErrorMessage),
    );
  }
}

/// Punto de entrada público — firma idéntica a la original para que los
/// ~13 call sites en repositorios no cambien.
///
/// Delega a [handlerExceptionHttpTestable] con los valores de producción.
Future<ApiResult<T>> handlerExceptionHttp<T>({
  required Future<T> Function() function,
}) => handlerExceptionHttpTestable(
  function: function,
  crashReporter: _crashReporter(),
  isDebug: kDebugMode,
);

String _getDioErrorMessage(DioException exception) {
  final responseMessage = _extractResponseMessage(exception.response?.data);
  if (responseMessage != null && responseMessage.isNotEmpty) {
    return responseMessage;
  }

  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'La solicitud tardó demasiado. Revisa tu conexión e intenta de nuevo.';
    case DioExceptionType.connectionError:
      return 'No pudimos conectarnos al servidor. Revisa tu conexión a internet.';
    case DioExceptionType.badCertificate:
      return 'No pudimos validar la conexión segura con el servidor.';
    case DioExceptionType.cancel:
      return 'La solicitud fue cancelada.';
    case DioExceptionType.badResponse:
      return _getHttpStatusErrorMessage(exception.response?.statusCode);
    case DioExceptionType.unknown:
      return _genericErrorMessage;
  }
}

String? _extractResponseMessage(Object? responseData) {
  if (responseData is String) {
    return responseData;
  }

  if (responseData is Map<String, dynamic>) {
    final message = responseData['message'];
    if (message is String) {
      return message;
    }
    if (message is List) {
      return message.whereType<String>().join('\n');
    }

    final error = responseData['error'];
    if (error is String) {
      return error;
    }
  }

  return null;
}

String _getHttpStatusErrorMessage(int? statusCode) {
  switch (statusCode) {
    case 400:
      return 'La información enviada no es válida.';
    case 401:
      return 'Tu sesión expiró. Inicia sesión nuevamente.';
    case 403:
      return 'No tienes permisos para realizar esta acción.';
    case 404:
      return 'No encontramos la información solicitada.';
    case 409:
      return 'Ya existe un registro con esta información.';
    default:
      if (statusCode != null && statusCode >= 500 && statusCode < 600) {
        return _genericErrorMessage;
      }
      return _genericErrorMessage;
  }
}

Future<Either<DomainException, Model>> executeService<Model>({
  required Future<Model> Function() function,
}) async {
  final result = await handlerExceptionHttp<Model>(function: function);

  switch (result) {
    case final Success<Model> success:
      return Right(success.data);
    case final Failure<Model> failure:
      return Left(failure.dataException);
    default:
      return Left(DomainException(message: 'Unexpected result type: $result'));
  }
}

String _getFirebaseAuthErrorMessage(String? code) {
  switch (code) {
    // Por seguridad (anti-enumeración de cuentas) NO se revela si el correo
    // existe ni si la contraseña es la que falla: mensaje único y genérico.
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'email-already-in-use':
      return 'Correo o contraseña incorrectos.';
    case 'weak-password':
      return 'Password is too weak';
    case 'invalid-email':
      return 'Invalid email address';
    case 'user-disabled':
      return 'User account has been disabled';
    case 'too-many-requests':
      return 'Too many login attempts. Try again later';
    case 'operation-not-allowed':
      return 'This operation is not allowed';
    case 'credential-already-in-use':
      return 'This account is already in use';
    case 'requires-recent-login':
      return 'Please login again before performing this operation';
    case 'network-request-failed':
      return 'Network error. Please check your connection';
    default:
      return _genericErrorMessage;
  }
}

String _getPlatformExceptionErrorMessage(String code) {
  switch (code) {
    case 'sign_in_failed':
      return 'Google sign-in failed. Please check your internet connection and try again';
    case 'sign_in_cancelled':
      return 'Google sign-in was cancelled';
    case 'network_error':
      return 'Network error. Please check your internet connection';
    case 'DEVELOPER_ERROR':
      return 'Developer error. Please contact support';
    default:
      return _genericErrorMessage;
  }
}
