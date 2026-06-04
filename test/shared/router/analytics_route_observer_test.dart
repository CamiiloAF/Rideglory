import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_screen_names.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/shared/router/analytics_route_observer.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

/// Crea una ruta de prueba con el [settingsName] dado.
Route<dynamic> _fakeRoute(String? settingsName) {
  return PageRouteBuilder<void>(
    settings: RouteSettings(name: settingsName),
    pageBuilder: (ctx, anim, secAnim) => const SizedBox.shrink(),
  );
}

void main() {
  late MockAnalyticsService analytics;
  late AnalyticsRouteObserver observer;

  setUp(() {
    analytics = MockAnalyticsService();
    observer = AnalyticsRouteObserver(analytics);
    when(() => analytics.logScreenView(any())).thenAnswer((_) async {});
  });

  // T1 — Resolución de nombre: didPush con path mapeado → 1 logScreenView
  test(
    'T1 — didPush con settings.name mapeado emite nombre canónico exactamente 1 vez',
    () async {
      final route = _fakeRoute(AnalyticsScreenNames.branchRootPaths[2]); // /events

      observer.didPush(route, null);

      verify(() => analytics.logScreenView('events')).called(1);
    },
  );

  // T2 — 5 rutas con params, sin id
  test(
    'T2 — didPush para 5 rutas (incluida event_detail_by_id) emite nombres canónicos sin id dinámico',
    () async {
      int callCount = 0;
      final capturedNames = <String>[];
      when(() => analytics.logScreenView(any())).thenAnswer((inv) async {
        callCount++;
        capturedNames.add(inv.positionalArguments.first as String);
      });

      // Reiniciar observer para limpio
      observer = AnalyticsRouteObserver(analytics);

      // Para event_detail_by_id y event_detail se emite el mismo nombre canónico;
      // el dedupe absorbe el segundo. Emitimos con rutas alternas para 5 llamadas.
      final routesDistinct = [
        _fakeRoute('/events/detail-by-id'),  // event_detail
        _fakeRoute('/events/registration'),   // event_registration
        _fakeRoute('/vehicles/detail'),        // vehicle_detail
        _fakeRoute('/maintenances/detail'),    // maintenance_detail
        _fakeRoute('/notifications'),          // notifications
      ];

      for (final route in routesDistinct) {
        observer.didPush(route, null);
      }

      expect(callCount, equals(5));
      // Ninguno contiene id / segmento dinámico.
      for (final name in capturedNames) {
        expect(name, isNot(contains('id')));
        expect(name, isNot(contains('?')));
        expect(name, isNot(contains('/')));
      }
    },
  );

  // T3 — pushReplacement no duplica
  test(
    'T3 — didReplace hacia el mismo nombre canónico genera 0 emisiones extra',
    () async {
      final routeA = _fakeRoute('/home');
      final routeB = _fakeRoute('/home');
      final routeC = _fakeRoute('/events');

      observer.didPush(routeA, null); // emite home
      observer.didReplace(newRoute: routeB, oldRoute: routeA); // dedupe → 0
      observer.didReplace(newRoute: routeC, oldRoute: routeB); // emite events

      verify(() => analytics.logScreenView('home')).called(1);
      verify(() => analytics.logScreenView('events')).called(1);
      verifyNever(() => analytics.logScreenView(any(
        that: equals('home'),
      )));
    },
  );

  // T5 — Push inicial de branch + primera activación del listener → 1 screen_view neto
  test(
    'T5 — push inicial de branch seguido de notifyEmitted dedupe → 1 screen_view neto',
    () async {
      final branchInitRoute = _fakeRoute('/home');

      // Simula el didPush que notifyRootObserver reenvía al observer raíz.
      observer.didPush(branchInitRoute, null); // emite home → _lastEmittedName = home

      // El ShellScreenViewTracker llama notifyEmitted cuando activa el branch.
      // Si ya emitió 'home' con el mismo nombre, el tracker lo notifica (verdad de tabs).
      // El observer debe absorber duplicado gracias al _lastEmittedName compartido.
      observer.notifyEmitted('home'); // sincrono, sin llamada al analytics

      verify(() => analytics.logScreenView('home')).called(1);
    },
  );

  // T6 — didPop revela previousRoute
  test(
    'T6 — didPop emite nombre canónico de previousRoute (pantalla revelada), no de route',
    () async {
      final routeA = _fakeRoute('/home');
      final routeB = _fakeRoute('/events');

      observer.didPush(routeA, null); // home
      observer.didPush(routeB, null); // events

      // Pop de B revela A → debe emitir home
      observer.didPop(routeB, routeA);

      verify(() => analytics.logScreenView('home')).called(2); // push + pop
      verify(() => analytics.logScreenView('events')).called(1); // solo push
    },
  );

  // T7a — /profile/edit emite profile_edit
  test(
    'T7a — didPush con settings.name=/profile/edit emite profile_edit',
    () async {
      final route = _fakeRoute('/profile/edit');
      observer.didPush(route, null);
      verify(() => analytics.logScreenView('profile_edit')).called(1);
    },
  );

  // T7b — settings.name == null → 0 emisiones, sin excepción
  test(
    'T7b — didPush con settings.name==null no emite screen_view ni lanza',
    () async {
      final route = _fakeRoute(null);
      expect(() => observer.didPush(route, null), returnsNormally);
      verifyNever(() => analytics.logScreenView(any()));
    },
  );

  // T7c — path no mapeado → 0 emisiones
  test(
    'T7c — didPush con path no mapeado no emite screen_view',
    () async {
      final route = _fakeRoute('/unknown/path/not/mapped');
      observer.didPush(route, null);
      verifyNever(() => analytics.logScreenView(any()));
    },
  );

  // T8 — Gating: con no-op, ningún envío real
  test(
    'T8 — con AnalyticsService no-op, logScreenView no lanza ni envía',
    () async {
      // La no-op tiene logScreenView como Future vacío; verificar que no lanza.
      final noOpAnalytics = _NoOpAnalyticsService();
      final noOpObserver = AnalyticsRouteObserver(noOpAnalytics);
      final route = _fakeRoute('/home');

      expect(() => noOpObserver.didPush(route, null), returnsNormally);
      expect(noOpAnalytics.callCount, equals(1));
    },
  );

  // Dedupe: re-seleccionar el mismo path consecutivamente → 1 emisión total
  test(
    'Dedupe — emitir la misma pantalla dos veces consecutivas produce solo 1 logScreenView',
    () async {
      final routeA = _fakeRoute('/home');
      final routeB = _fakeRoute('/home');

      observer.didPush(routeA, null);
      observer.didPush(routeB, null); // dedupe, mismo nombre

      verify(() => analytics.logScreenView('home')).called(1);
    },
  );
}

/// No-op de analytics para test de gating (T8).
class _NoOpAnalyticsService implements AnalyticsService {
  int callCount = 0;

  @override
  Future<void> logScreenView(String screenName) async {
    callCount++;
  }

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<void> setUserId(String hashedId) async {}

  @override
  Future<void> setUserProperty(String name, String value) async {}
}
