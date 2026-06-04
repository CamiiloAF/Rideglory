import 'crash_reporter.dart';

/// Implementación no-op para pruebas. Test double manual (no registrado en DI);
/// el CrashReporter por defecto es [FirebaseCrashReporter]. Todos los métodos
/// son async vacíos para que flutter test no contacte Firebase.
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
