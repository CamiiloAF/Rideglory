import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/timezone.dart' as tz;

import 'local_notifications_initializer.dart';

/// Programa y cancela el recordatorio local del próximo servicio de un
/// mantenimiento (D6: sin servidor propio, el recordatorio vive en el
/// dispositivo). Se cancela siempre que el registro se edita o se borra.
@injectable
class MaintenanceNotificationScheduler {
  const MaintenanceNotificationScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'maintenance_reminders';
  static const _channelName = 'Recordatorios de mantenimiento';

  Future<bool> requestPermission() =>
      LocalNotificationsInitializer.requestPermission();

  Future<void> scheduleForMaintenance({
    required String maintenanceId,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    final scheduledDate = tz.TZDateTime.from(date, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _notificationId(maintenanceId),
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(String maintenanceId) =>
      _plugin.cancel(_notificationId(maintenanceId));

  int _notificationId(String maintenanceId) =>
      maintenanceId.hashCode & 0x7fffffff;
}
