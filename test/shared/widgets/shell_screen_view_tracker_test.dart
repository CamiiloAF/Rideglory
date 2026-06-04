import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/shared/router/analytics_route_observer.dart';
import 'package:rideglory/shared/widgets/shell_screen_view_tracker.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAnalyticsRouteObserver extends Mock
    implements AnalyticsRouteObserver {}

/// Widget de prueba que controla el índice del [ShellScreenViewTracker]
/// usando [ShellScreenViewTracker.forTesting] — no necesita un
/// [StatefulNavigationShell] real.
class _TrackerDriver extends StatefulWidget {
  const _TrackerDriver({
    super.key,
    required this.analytics,
    required this.observer,
    required this.initialIndex,
  });

  final AnalyticsService analytics;
  final AnalyticsRouteObserver observer;
  final int initialIndex;

  @override
  State<_TrackerDriver> createState() => _TrackerDriverState();
}

class _TrackerDriverState extends State<_TrackerDriver> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void goToIndex(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    // ignore: invalid_use_of_visible_for_testing_member
    return ShellScreenViewTracker.forTesting(
      analytics: widget.analytics,
      observer: widget.observer,
      currentIndex: _index,
      child: const SizedBox.shrink(),
    );
  }
}

/// Wrapper mínimo de WidgetsApp necesario para pumpWidget.
class _App extends StatelessWidget {
  const _App({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFF000000),
      builder: (ctx, child2) => child,
    );
  }
}

void main() {
  late MockAnalyticsService analytics;
  late MockAnalyticsRouteObserver observer;

  setUp(() {
    analytics = MockAnalyticsService();
    observer = MockAnalyticsRouteObserver();
    when(() => analytics.logScreenView(any())).thenAnswer((_) async {});
    when(() => observer.notifyEmitted(any())).thenReturn(null);
  });

  // T4 — Cambio de pestaña por índice: 0→1→1→2 produce 2 emisiones extra
  // (más 1 del initState en índice 0).
  testWidgets(
    'T4 — índice 0→1→1→2: initState emite home; 1 emite garage; re-1 dedupe; 2 emite events',
    (tester) async {
      final driverKey = GlobalKey<_TrackerDriverState>();

      await tester.pumpWidget(
        _App(
          child: _TrackerDriver(
            key: driverKey,
            analytics: analytics,
            observer: observer,
            initialIndex: 0,
          ),
        ),
      );

      // initState → emite branch 0 (home).
      verify(() => analytics.logScreenView('home')).called(1);

      // Cambiar a index 1 (garage).
      driverKey.currentState!.goToIndex(1);
      await tester.pump();
      verify(() => analytics.logScreenView('garage')).called(1);

      // Re-seleccionar index 1 → dedupe, 0 emisiones extra.
      driverKey.currentState!.goToIndex(1);
      await tester.pump();
      verifyNever(() => analytics.logScreenView('garage'));

      // Cambiar a index 2 (events).
      driverKey.currentState!.goToIndex(2);
      await tester.pump();
      verify(() => analytics.logScreenView('events')).called(1);

      // No deben haber más llamadas.
      verifyNoMoreInteractions(analytics);
    },
  );

  // T5 — notifyEmitted sincroniza el estado de dedupe entre observer y tracker.
  testWidgets(
    'T5 — notifyEmitted sincroniza dedupe: 1 sola emisión de analytics al arrancar',
    (tester) async {
      // El observer raíz ya notificó 'home' (push inicial del branch).
      final realObserver = AnalyticsRouteObserver(analytics);
      when(() => analytics.logScreenView(any())).thenAnswer((_) async {});
      realObserver.notifyEmitted('home');

      await tester.pumpWidget(
        _App(
          child: _TrackerDriver(
            analytics: analytics,
            observer: realObserver,
            initialIndex: 0,
          ),
        ),
      );

      // El tracker emite logScreenView('home') en initState (llama analytics directamente).
      verify(() => analytics.logScreenView('home')).called(1);
      verifyNoMoreInteractions(analytics);
    },
  );

  // Dedupe local — re-seleccionar el mismo tab consecutivamente.
  testWidgets(
    'Dedupe local — re-seleccionar el mismo tab 3 veces produce 0 emisiones extra',
    (tester) async {
      final driverKey = GlobalKey<_TrackerDriverState>();

      await tester.pumpWidget(
        _App(
          child: _TrackerDriver(
            key: driverKey,
            analytics: analytics,
            observer: observer,
            initialIndex: 0,
          ),
        ),
      );

      verify(() => analytics.logScreenView('home')).called(1);

      for (int i = 0; i < 3; i++) {
        driverKey.currentState!.goToIndex(0);
        await tester.pump();
      }

      verifyNoMoreInteractions(analytics);
    },
  );

  // Verificar que notifyEmitted se llama con el nombre correcto.
  testWidgets(
    'notifyEmitted se llama en el observer con el nombre canónico al emitir',
    (tester) async {
      final driverKey = GlobalKey<_TrackerDriverState>();

      await tester.pumpWidget(
        _App(
          child: _TrackerDriver(
            key: driverKey,
            analytics: analytics,
            observer: observer,
            initialIndex: 1, // garage
          ),
        ),
      );

      verify(() => observer.notifyEmitted('garage')).called(1);
    },
  );
}
