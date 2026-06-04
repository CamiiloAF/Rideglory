import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/services/analytics/analytics_screen_names.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/shared/router/analytics_route_observer.dart';

/// Widget que emite `screen_view` al cambiar de pestaña en el
/// [StatefulShellRoute.indexedStack].
///
/// El [NavigatorObserver] raíz NO ve los cambios de tab (el shell solo cambia
/// el índice del [IndexedStack] sin push/pop). Este widget observa
/// [StatefulNavigationShell.currentIndex] en [didUpdateWidget] y emite el
/// nombre canónico del branch activado, con dedupe por índice.
///
/// Dedupe doble:
/// 1. **Por índice (local):** re-seleccionar el mismo tab → 0 emisiones.
/// 2. **Por nombre (compartido con el observer):** si el push inicial del
///    branch ya fue emitido por [AnalyticsRouteObserver], el observer
///    actualiza [_lastEmittedName] vía [AnalyticsRouteObserver.notifyEmitted];
///    el tracker emite igualmente y el observer absorbe el duplicado en la
///    próxima vez (fuente de verdad de tabs = tracker).
///
/// Un widget por archivo; sin métodos que retornen widgets.
class ShellScreenViewTracker extends StatefulWidget {
  const ShellScreenViewTracker({
    super.key,
    required StatefulNavigationShell navigationShell,
    required this.analytics,
    required this.observer,
    required this.child,
    @visibleForTesting this.currentIndexOverride,
  }) : _navigationShell = navigationShell;

  /// Constructor solo para tests: no requiere [StatefulNavigationShell].
  ///
  /// Se usa junto con [currentIndexOverride] para inyectar el índice
  /// directamente sin instanciar el shell real (que requiere go_router
  /// internals no disponibles en tests unitarios).
  @visibleForTesting
  const ShellScreenViewTracker.forTesting({
    super.key,
    required this.analytics,
    required this.observer,
    required this.child,
    required int currentIndex,
  })  : _navigationShell = null,
        currentIndexOverride = currentIndex;

  final StatefulNavigationShell? _navigationShell;
  final AnalyticsService analytics;
  final AnalyticsRouteObserver observer;
  final Widget child;

  /// Sobreescribe `navigationShell.currentIndex` — solo para tests.
  /// En producción este campo es `null` y se usa el índice real del shell.
  @visibleForTesting
  final int? currentIndexOverride;

  @override
  State<ShellScreenViewTracker> createState() => _ShellScreenViewTrackerState();
}

class _ShellScreenViewTrackerState extends State<ShellScreenViewTracker> {
  int? _lastEmittedIndex;

  int get _currentIndex =>
      widget.currentIndexOverride ?? widget._navigationShell!.currentIndex;

  @override
  void initState() {
    super.initState();
    // Emitir el branch inicial al arrancar el shell.
    _maybeEmit(_currentIndex);
  }

  @override
  void didUpdateWidget(ShellScreenViewTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeEmit(_currentIndex);
  }

  void _maybeEmit(int index) {
    if (index == _lastEmittedIndex) return;
    _lastEmittedIndex = index;

    const branchPaths = AnalyticsScreenNames.branchRootPaths;
    if (index < 0 || index >= branchPaths.length) return;

    final name = AnalyticsScreenNames.forPath(branchPaths[index]);
    if (name == null) return;

    // Notificar al observer para que comparta el estado de dedupe por nombre.
    widget.observer.notifyEmitted(name);
    widget.analytics.logScreenView(name);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
