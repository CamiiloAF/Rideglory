import 'package:injectable/injectable.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:rideglory/core/observability/pii_denylist.dart';
import 'crash_reporter.dart';

/// Implementación de producción que delega al SDK de Sentry.
///
/// ÚNICO archivo del proyecto autorizado a importar package:sentry_flutter
/// ni package:sentry. Invariante verificable con grep.
///
/// Registrado exclusivamente en el environment 'prod' de DI. En dev/test
/// lo reemplaza [NoOpCrashReporter].
@Injectable(as: CrashReporter)
@Environment('prod')
class SentryCrashReporter implements CrashReporter {
  /// Sin inyección: Sentry es un singleton global inicializado en main.dart.
  SentryCrashReporter();

  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    List<String> information = const [],
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stack,
      hint: reason != null ? Hint.withMap({'reason': reason}) : null,
      withScope: (scope) {
        for (final entry in information) {
          final parts = entry.split('=');
          if (parts.length == 2) {
            final key = parts[0].trim();
            final value = parts[1].trim();
            if (!_isPiiKey(key)) {
              scope.setTag(key, value);
            }
          }
        }
      },
    );
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    // No-op: el gating se realiza en beforeSend / DSN vacío en main.dart.
    // Sentry no expone un toggle dinámico; la habilitación se controla
    // por DSN (vacío en dev) y beforeSend (retorna null en kDebugMode).
  }
}

/// Retorna true si la clave está en la denylist PII.
bool _isPiiKey(String key) {
  final lower = key.toLowerCase();
  return kPiiDenylist.any((denied) => lower.contains(denied));
}

/// Redacta claves PII de las tags de un evento Sentry.
///
/// Usado en [beforeSend] en main.dart para asegurar que ningún dato
/// sensible llegue al servidor de Sentry.
SentryEvent scrubPiiFromEvent(SentryEvent event) {
  final tags = event.tags;
  if (tags == null || tags.isEmpty) return event;

  final scrubbed = <String, String>{};
  for (final entry in tags.entries) {
    if (_isPiiKey(entry.key)) {
      scrubbed[entry.key] = '[redacted]';
    } else {
      scrubbed[entry.key] = entry.value;
    }
  }
  return event.copyWith(tags: scrubbed);
}

/// Redacta claves PII de los datos de un breadcrumb Sentry.
///
/// Usado en [beforeBreadcrumb] en main.dart.
Breadcrumb scrubPiiFromBreadcrumb(Breadcrumb crumb) {
  final data = crumb.data;
  if (data == null || data.isEmpty) return crumb;

  final scrubbed = <String, dynamic>{};
  for (final entry in data.entries) {
    if (_isPiiKey(entry.key)) {
      scrubbed[entry.key] = '[redacted]';
    } else {
      scrubbed[entry.key] = entry.value;
    }
  }
  return crumb.copyWith(data: scrubbed);
}
