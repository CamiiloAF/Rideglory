import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';

/// Resultado de clasificación de un error HTTP.
///
/// Clase pura (sin Flutter, sin Firebase SDK directo) que encapsula si un
/// error debe reportarse como no-fatal y con qué metadatos.
final class NetworkErrorClassification {
  const NetworkErrorClassification({
    required this.shouldReport,
    this.category,
    this.reason,
    this.httpStatus,
    this.dioType,
  });

  /// Si el error debe reportarse como no-fatal en Crashlytics.
  final bool shouldReport;

  /// Categoría del error (p.ej. `network`, `platform_unexpected`,
  /// `unexpected`). Proviene de [AnalyticsParams].
  final String? category;

  /// Razón corta estable (p.ej. `network_timeout`, `network_5xx`).
  /// Proviene de [AnalyticsParams].
  final String? reason;

  /// Código HTTP de estado, si aplica.
  final int? httpStatus;

  /// Nombre del tipo de [DioExceptionType], si aplica.
  final String? dioType;

  /// No reporta — singleton reutilizable.
  static const NetworkErrorClassification skip = NetworkErrorClassification(
    shouldReport: false,
  );
}

/// Conjunto de códigos de [FirebaseAuthException] que son errores de
/// negocio esperados y NO deben reportarse como no-fatales.
const Set<String> _expectedFirebaseAuthCodes = {
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
};

/// Conjunto de códigos de [PlatformException] conocidos del flujo de
/// sign-in que NO deben reportarse como no-fatales.
const Set<String> _expectedPlatformCodes = {
  'sign_in_cancelled',
  'sign_in_failed',
  'network_error',
};

/// Clasifica un [DioException] según la matriz de severidad G5.
///
/// Devuelve la clasificación que indica si se debe reportar el error
/// como no-fatal y con qué metadatos.
NetworkErrorClassification classifyDioException(DioException exception) {
  final typeName = exception.type.name;
  final statusCode = exception.response?.statusCode;

  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return NetworkErrorClassification(
        shouldReport: true,
        category: AnalyticsParams.categoryNetwork,
        reason: AnalyticsParams.reasonNetworkTimeout,
        dioType: typeName,
      );

    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return NetworkErrorClassification(
        shouldReport: true,
        category: AnalyticsParams.categoryNetwork,
        reason: AnalyticsParams.reasonNetworkConnection,
        dioType: typeName,
      );

    case DioExceptionType.badResponse:
      if (statusCode != null && statusCode >= 500) {
        return NetworkErrorClassification(
          shouldReport: true,
          category: AnalyticsParams.categoryNetwork,
          reason: AnalyticsParams.reasonNetwork5xx,
          httpStatus: statusCode,
          dioType: typeName,
        );
      }
      // 4xx (negocio esperado) y otros — no reportar.
      return NetworkErrorClassification.skip;

    case DioExceptionType.cancel:
      return NetworkErrorClassification.skip;

    case DioExceptionType.unknown:
      return NetworkErrorClassification(
        shouldReport: true,
        category: AnalyticsParams.categoryNetwork,
        reason: AnalyticsParams.reasonNetworkConnection,
        dioType: typeName,
      );
  }
}

/// Clasifica un [FirebaseAuthException] según la matriz de severidad G5.
NetworkErrorClassification classifyFirebaseAuthException(
  FirebaseAuthException exception,
) {
  if (exception.code == 'network-request-failed') {
    return const NetworkErrorClassification(
      shouldReport: true,
      category: AnalyticsParams.categoryNetwork,
      reason: AnalyticsParams.reasonFirebaseNetwork,
    );
  }

  if (_expectedFirebaseAuthCodes.contains(exception.code)) {
    return NetworkErrorClassification.skip;
  }

  // Código desconocido — podría ser un bug; reportar para visibilidad.
  return const NetworkErrorClassification(
    shouldReport: true,
    category: AnalyticsParams.categoryNetwork,
    reason: AnalyticsParams.reasonFirebaseNetwork,
  );
}

/// Clasifica un [PlatformException] según la matriz de severidad G5.
NetworkErrorClassification classifyPlatformException(
  PlatformException exception,
) {
  if (_expectedPlatformCodes.contains(exception.code)) {
    return NetworkErrorClassification.skip;
  }

  return const NetworkErrorClassification(
    shouldReport: true,
    category: AnalyticsParams.categoryPlatformUnexpected,
    reason: AnalyticsParams.reasonPlatformUnexpected,
  );
}

/// Sanitiza una URI eliminando query string, fragmento e ids dinámicos.
///
/// Retorna `host + path` con segmentos que parezcan ids (UUIDs, números
/// puros, 24+ chars hex) reemplazados por `:id`. Sin PII, sin body,
/// sin tokens.
///
/// Ejemplo: `https://api.rideglory.com/events/abc-123-xyz` → `api.rideglory.com/events/:id`
String sanitizeEndpoint(String? urlString) {
  if (urlString == null || urlString.isEmpty) return 'unknown';

  final uri = Uri.tryParse(urlString);
  if (uri == null) return 'unknown';

  final host = uri.host.isNotEmpty ? uri.host : 'unknown';
  final rawPath = uri.path;

  // Enmascarar segmentos dinámicos: UUIDs, números puros, hex 24+ chars.
  final segments = rawPath.split('/').map((segment) {
    if (segment.isEmpty) return segment;
    // UUID v4 pattern
    if (RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(segment)) {
      return ':id';
    }
    // Número puro
    if (RegExp(r'^\d+$').hasMatch(segment)) {
      return ':id';
    }
    // Hex 24+ chars (MongoDB ObjectId, etc.)
    if (RegExp(r'^[0-9a-f]{24,}$', caseSensitive: false).hasMatch(segment)) {
      return ':id';
    }
    return segment;
  });

  final cleanPath = segments.join('/');
  // Truncar si excede 100 chars (límite GA4 para valores string).
  final full = '$host$cleanPath';
  return full.length > 100 ? full.substring(0, 100) : full;
}
