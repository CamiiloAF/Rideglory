import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/background_tracking_service.dart';
import 'live_ride_tracking_task_handler.dart';

/// D14: foreground service de Android (con notificación persistente y
/// botón **Detener**) / `location` en `UIBackgroundModes` de iOS. El
/// handler corre en un isolate aparte (ver `live_ride_tracking_task_handler.dart`
/// para la decisión de cómo se lleva ahí la sesión de Supabase).
@Injectable(as: BackgroundTrackingService)
class ForegroundTaskBackgroundTrackingService
    implements BackgroundTrackingService {
  ForegroundTaskBackgroundTrackingService(this._client) {
    FlutterForegroundTask.initCommunicationPort();
  }

  final SupabaseClient _client;

  static const String _dataKeyEventId = 'live_ride_event_id';
  static const String _dataKeyAccessToken = 'live_ride_access_token';
  static const String _stopButtonId = 'live_ride_stop';

  bool _initialized = false;

  void _ensureInitialized() {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'rideglory_live_ride',
        channelName: 'Rodada en vivo',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        allowWakeLock: true,
        autoRunOnBoot: false,
      ),
    );
    _initialized = true;
  }

  @override
  Future<void> start({
    required String eventId,
    required String notificationTitle,
    required String notificationBody,
    required String stopButtonLabel,
  }) async {
    _ensureInitialized();
    if (await isRunning()) return;

    // El handler corre en un isolate propio sin bindings de Flutter: no
    // puede leer `Supabase.instance` (eso requiere `SharedPreferences`
    // inicializado vía plugins de la app). En vez de reinicializar
    // `Supabase.initialize` ahí, se pasa el access token vigente por
    // `FlutterForegroundTask.saveData` (respaldado por `SharedPreferences`
    // nativo, accesible desde cualquier isolate) y el handler construye un
    // `SupabaseClient` puro con ese token como header — ver
    // `LiveRideTaskHandler`.
    final session = _client.auth.currentSession;
    await FlutterForegroundTask.saveData(key: _dataKeyEventId, value: eventId);
    await FlutterForegroundTask.saveData(
      key: _dataKeyAccessToken,
      value: session?.accessToken ?? '',
    );

    await FlutterForegroundTask.startService(
      notificationTitle: notificationTitle,
      notificationText: notificationBody,
      notificationButtons: [
        NotificationButton(id: _stopButtonId, text: stopButtonLabel),
      ],
      callback: startLiveRideTrackingCallback,
    );
  }

  @override
  Future<void> stop() async {
    if (!await isRunning()) return;
    await FlutterForegroundTask.stopService();
  }

  @override
  Future<bool> isRunning() => FlutterForegroundTask.isRunningService;
}
