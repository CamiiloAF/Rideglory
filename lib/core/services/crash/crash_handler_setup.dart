import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';

/// Registra los handlers globales de Flutter que delegan a [CrashReporter].
///
/// Aislado de [main.dart] para ser testeable sin runApp.
/// En debug mode ([isDebug]=true) los handlers NO se registran — gating estricto.
void registerCrashHandlers({
  required bool isDebug,
  required CrashReporter reporter,
}) {
  if (isDebug) return;

  FlutterError.onError = (details) {
    reporter.recordError(
      details.exception,
      details.stack,
      reason: details.exceptionAsString(),
      fatal: true,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.recordError(error, stack, fatal: true);
    return true;
  };
}
