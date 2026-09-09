import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

import '../services/notifications/local_notifications_initializer.dart';

/// Registra el `FlutterLocalNotificationsPlugin` ya inicializado (ver
/// `main.dart`, donde se llama `LocalNotificationsInitializer.init()` antes
/// de `configureDependencies`). Lo consumen `DocumentReminderScheduler` (D6:
/// recordatorios de vencimiento de documentos) y `MaintenanceNotificationScheduler`
/// (recordatorios de mantenimiento), ambos sin red.
@module
abstract class NotificationsModule {
  @lazySingleton
  FlutterLocalNotificationsPlugin get notificationsPlugin =>
      LocalNotificationsInitializer.plugin;
}
