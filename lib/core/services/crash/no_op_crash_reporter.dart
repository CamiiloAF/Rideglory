import 'package:injectable/injectable.dart';

import 'crash_reporter.dart';

/// Implementación no-op para el entorno de pruebas.
///
/// Todos los métodos son async vacíos para que flutter test
/// no contacte Firebase ni lance excepciones.
@Injectable(as: CrashReporter, env: [Environment.test])
class NoOpCrashReporter implements CrashReporter {
  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}
}
