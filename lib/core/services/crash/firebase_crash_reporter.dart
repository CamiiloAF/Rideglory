import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'crash_reporter.dart';

/// Implementación de producción que delega al SDK de Firebase Crashlytics.
///
/// ÚNICO archivo del proyecto autorizado a importar package:firebase_crashlytics.
/// Invariante G0 — verificable con grep.
///
/// NOTA: La anotación @Injectable fue retirada. Este archivo se elimina
/// tras la validación prod-like (D10/D13). Ver
/// docs/exec-runs/observability-sentry/phase-03-validacion-prod-like.md.
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    List<String> information = const [],
  }) =>
      _crashlytics.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
        information: information,
      );

  @override
  Future<void> setEnabled(bool enabled) =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);
}
