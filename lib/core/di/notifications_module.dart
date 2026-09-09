import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

/// Registra el plugin de notificaciones locales que usa
/// `DocumentReminderScheduler` (D6: recordatorios de vencimiento sin red).
@module
abstract class NotificationsModule {
  @lazySingleton
  FlutterLocalNotificationsPlugin get notificationsPlugin => FlutterLocalNotificationsPlugin();
}
