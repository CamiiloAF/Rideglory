import 'package:flutter/widgets.dart';
import 'package:rideglory/core/services/analytics/analytics_screen_names.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';

/// Observer de navegación que emite `screen_view` automáticamente por cada
/// transición de ruta en el [GoRouter] raíz.
///
/// Responsabilidades:
/// - Rutas top-level (push / replace / pop).
/// - Push inicial de cada branch del [StatefulShellRoute.indexedStack]
///   (visible gracias al flag `notifyRootObserver = true` por defecto en
///   go_router).
///
/// Lo que **no** cubre (manejado por [ShellScreenViewTracker]):
/// - Re-activación de tabs ya construidos (cambio de `currentIndex` del
///   shell sin push/pop en ningún Navigator).
///
/// Dedupe: no re-emite si el nombre canónico calculado es igual al último
/// emitido. Esto absorbe:
/// - `pushReplacement` a la misma pantalla lógica → 0 extra.
/// - Pops sucesivos que revelan la misma pantalla.
///
/// Gating: el gating debug/test vive en la impl de [AnalyticsService];
/// este observer nunca consulta `kDebugMode`.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;

  String? _lastEmittedName;

  String? _nameFor(Route<dynamic>? route) {
    final path = route?.settings.name;
    if (path == null) return null;
    return AnalyticsScreenNames.forPath(path);
  }

  void _emit(String? name) {
    if (name == null) return;
    if (name == _lastEmittedName) return;
    _lastEmittedName = name;
    _analytics.logScreenView(name);
  }

  /// Pantalla que **entra**: [route] (la empujada).
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emit(_nameFor(route));
  }

  /// Pantalla que **entra**: [newRoute] (la de reemplazo).
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _emit(_nameFor(newRoute));
  }

  /// Pantalla que **queda revelada**: [previousRoute] (no la que se va).
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emit(_nameFor(previousRoute));
  }

  /// Expone el último nombre emitido — útil para tests y para que
  /// [ShellScreenViewTracker] comparta el dedupe de nombre.
  String? get lastEmittedName => _lastEmittedName;

  /// Permite al [ShellScreenViewTracker] actualizar el último nombre emitido
  /// cuando lo hace el listener de índice (fuente única de verdad para tabs).
  void notifyEmitted(String name) {
    _lastEmittedName = name;
  }
}
