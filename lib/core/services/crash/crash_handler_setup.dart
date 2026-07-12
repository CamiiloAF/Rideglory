import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'crash_reporter.dart';

/// Race conocida del SDK `mapbox_maps_flutter` (2.24.3): `Style.addSource`
/// no espera su propia llamada interna a `setStyleSourceProperties`, que
/// puede lanzar después de que el widget que dibuja la ruta ya se desmontó
/// (p. ej. al navegar fuera del detalle de evento). Inofensiva — el mapa ya
/// se está destruyendo cuando ocurre — pero escapa como error async no
/// manejado porque el `Future` detached del SDK no pasa por ningún
/// `try/catch` de la app.
bool isBenignMapboxSourceRace(Object error) {
  return error is PlatformException &&
      (error.message?.contains('is not in style') ?? false);
}

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
    if (isBenignMapboxSourceRace(details.exception)) return;
    reporter.recordError(
      details.exception,
      details.stack,
      reason: details.exceptionAsString(),
      fatal: true,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (isBenignMapboxSourceRace(error)) return true;
    reporter.recordError(error, stack, fatal: true);
    return true;
  };
}
