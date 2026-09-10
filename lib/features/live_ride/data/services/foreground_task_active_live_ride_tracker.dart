import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:injectable/injectable.dart';

import '../../domain/active_live_ride_tracker.dart';
import 'live_ride_tracking_keys.dart';

/// Ver [ActiveLiveRideTracker]: reusa el storage de
/// `FlutterForegroundTask` (accesible desde el isolate del foreground
/// service) en vez de `shared_preferences` directo, para que el botón
/// "Detener" de la notificación pueda limpiar la misma clave que lee
/// `SignOutUseCase` desde el isolate principal.
@Injectable(as: ActiveLiveRideTracker)
class ForegroundTaskActiveLiveRideTracker implements ActiveLiveRideTracker {
  @override
  Future<void> save(String eventId) async {
    await FlutterForegroundTask.saveData(
      key: LiveRideTrackingKeys.activeEventId,
      value: eventId,
    );
  }

  @override
  Future<String?> read() {
    return FlutterForegroundTask.getData<String>(
      key: LiveRideTrackingKeys.activeEventId,
    );
  }

  @override
  Future<void> clear() async {
    await FlutterForegroundTask.removeData(
      key: LiveRideTrackingKeys.activeEventId,
    );
  }
}
