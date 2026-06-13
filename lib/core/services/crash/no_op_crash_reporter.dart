import 'package:injectable/injectable.dart';

import 'crash_reporter.dart';

/// Implementación no-op para dev y tests.
///
/// Registrada en DI para los environments 'dev' y 'test', de modo que
/// ningún código de prueba ni de desarrollo llame a Sentry ni a Firebase.
/// Todos los métodos son async vacíos.
@Injectable(as: CrashReporter)
@Environment('dev')
@Environment('test')
class NoOpCrashReporter implements CrashReporter {
  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    List<String> information = const [],
  }) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}
}
