import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_env.dart';

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
/// Limitación conocida (pendiente, fuera de este alcance): el access token
/// no se refresca dentro del isolate. Una rodada más larga que la vida del
/// token (~1 h) necesitará que la app en primer plano vuelva a llamar
/// `saveData` con un token fresco, o migrar a pasar el refresh token y
/// refrescar aquí mismo.
class LiveRideTrackingTaskHandler extends TaskHandler {
  SupabaseClient? _client;
  StreamSubscription<Position>? _positionSubscription;
  final Battery _battery = Battery();
  String? _eventId;
  DateTime _lastPublishAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const String _dataKeyEventId = 'live_ride_event_id';
  static const String _dataKeyAccessToken = 'live_ride_access_token';
  static const String _stopButtonId = 'live_ride_stop';
  static const Duration _minPublishInterval = Duration(seconds: 5);

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final eventId = await FlutterForegroundTask.getData<String>(
      key: _dataKeyEventId,
    );
    final accessToken = await FlutterForegroundTask.getData<String>(
      key: _dataKeyAccessToken,
    );
    _eventId = eventId;
    if (accessToken == null || accessToken.isEmpty || eventId == null) return;

    _client = SupabaseClient(
      AppEnv.supabaseUrl,
      AppEnv.supabaseAnonKey,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(distanceFilter: 25),
    ).listen(_onPosition);
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
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == _stopButtonId) {
      FlutterForegroundTask.stopService();
    }
  }
}
