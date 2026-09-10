import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_env.dart';
import 'live_ride_tracking_keys.dart';

/// Entry point del isolate del foreground service. `@pragma('vm:entry-point')`
/// es obligatorio: sin ella el compilador AOT elimina esta función porque no
/// hay ninguna llamada estática visible (la invoca el código nativo de
/// Android/iOS por nombre).
@pragma('vm:entry-point')
void startLiveRideTrackingCallback() {
  FlutterForegroundTask.setTaskHandler(LiveRideTrackingTaskHandler());
}

/// Publica la posición del rider cada ~5 s mientras la rodada sigue activa
/// (D14/D15). Corre en un isolate sin bindings de Flutter: construye su
/// propio `SupabaseClient` puro (`package:supabase`, reexportado por
/// `supabase_flutter`) autenticado con el access token que
/// `ForegroundTaskBackgroundTrackingService` guardó antes de arrancar el
/// servicio — no llama a `Supabase.initialize` aquí porque esa ruta
/// depende de `shared_preferences`/plugins que este isolate no tiene
/// garantizado tener listos.
///
/// Refresco de token: el access token dura ~1h y una rodada puede durar
/// más. `ForegroundTaskBackgroundTrackingService` también guarda el
/// refresh token; este handler lo usa con `client.auth.setSession` al
/// arrancar (por si el token guardado ya venía viejo) y cada 45 min con
/// un `Timer.periodic`, reconstruyendo `_client` con el access token
/// fresco que devuelve la respuesta (el mismo patrón de header estático
/// que el arranque, por la misma razón: sin `Supabase.initialize` en este
/// isolate, no hay sesión "viva" de la que `PostgrestClient` pueda leer
/// el token en cada request).
///
/// D22 (fin del tracking): tanto el botón "Detener" de la notificación
/// como cualquier otra causa de que el servicio se detenga pasan por
/// [onDestroy], que llama a `end_live_ride` (mejor esfuerzo — un fallo de
/// red aquí no debe bloquear que el servicio pare), borra la clave de
/// "rodada activa" que lee `SignOutUseCase`, y avisa a la app por
/// `sendDataToMain` para que `LiveRideCubit` pase a `notSharing` sin que
/// el rider tenga que reabrir la app. `end_live_ride` solo borra
/// `live_positions`, nunca toca un SOS.
class LiveRideTrackingTaskHandler extends TaskHandler {
  SupabaseClient? _client;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _refreshTimer;
  final Battery _battery = Battery();
  String? _eventId;
  String? _refreshToken;
  DateTime _lastPublishAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const Duration _minPublishInterval = Duration(seconds: 5);
  static const Duration _refreshInterval = Duration(minutes: 45);

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final eventId = await FlutterForegroundTask.getData<String>(
      key: LiveRideTrackingKeys.eventId,
    );
    final accessToken = await FlutterForegroundTask.getData<String>(
      key: LiveRideTrackingKeys.accessToken,
    );
    final refreshToken = await FlutterForegroundTask.getData<String>(
      key: LiveRideTrackingKeys.refreshToken,
    );
    _eventId = eventId;
    _refreshToken = (refreshToken != null && refreshToken.isNotEmpty)
        ? refreshToken
        : null;
    if (accessToken == null || accessToken.isEmpty || eventId == null) return;

    _client = _clientWithAccessToken(accessToken);

    if (_refreshToken != null) {
      await _refreshSession();
    }
    _refreshTimer = Timer.periodic(
      _refreshInterval,
      (_) => unawaited(_refreshSession()),
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(distanceFilter: 25),
    ).listen(_onPosition);
  }

  SupabaseClient _clientWithAccessToken(String accessToken) {
    return SupabaseClient(
      AppEnv.supabaseUrl,
      AppEnv.supabaseAnonKey,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }

  Future<void> _refreshSession() async {
    final refreshToken = _refreshToken;
    final client = _client;
    if (refreshToken == null || client == null) return;
    try {
      final response = await client.auth.setSession(refreshToken);
      final newAccessToken = response.session?.accessToken;
      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        _client = _clientWithAccessToken(newAccessToken);
      }
    } catch (_) {
      // Mejor esfuerzo: si el refresh falla (sin red en ese instante), la
      // próxima publicación de posición fallará silenciosamente (ver
      // `_onPosition`, también mejor esfuerzo) hasta que este mismo Timer
      // lo reintente en 45 min o el rider reabra la app.
    }
  }

  Future<void> _onPosition(Position position) async {
    final now = DateTime.now();
    if (now.difference(_lastPublishAt) < _minPublishInterval) return;
    _lastPublishAt = now;

    final eventId = _eventId;
    final client = _client;
    if (eventId == null || client == null) return;

    final batteryLevel = await _battery.batteryLevel;
    try {
      await client.rpc<void>(
        'upsert_live_position',
        params: {
          'p_event_id': eventId,
          'p_lat': position.latitude,
          'p_lng': position.longitude,
          'p_speed_kmh': position.speed * 3.6,
          'p_heading': position.heading,
          'p_battery_pct': batteryLevel,
          'p_accuracy_m': position.accuracy,
          'p_recorded_at': position.timestamp.toUtc().toIso8601String(),
        },
      );
    } catch (_) {
      // Publicación de posición "mejor esfuerzo": una lectura perdida no
      // es una emergencia (a diferencia del SOS) y la siguiente llegará en
      // ~5 s. No hay UI aquí para reportar el fallo.
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;

    await _endRideBestEffort();
    await FlutterForegroundTask.removeData(
      key: LiveRideTrackingKeys.activeEventId,
    );
    FlutterForegroundTask.sendDataToMain(
      LiveRideTrackingKeys.stoppedExternallyMessage,
    );
  }

  Future<void> _endRideBestEffort() async {
    final eventId = _eventId;
    final client = _client;
    if (eventId == null || client == null) return;
    try {
      await client.rpc<void>('end_live_ride', params: {'p_event_id': eventId});
    } catch (_) {
      // Mejor esfuerzo: `end_live_ride` es idempotente (borra
      // `live_positions`), así que si esto falla por falta de red al
      // parar, el servidor igual reconcilia cuando el rider vuelva a
      // tener señal (o `LiveRideCubit.load` al reabrir la app).
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == LiveRideTrackingKeys.stopButtonId) {
      FlutterForegroundTask.stopService();
    }
  }
}
