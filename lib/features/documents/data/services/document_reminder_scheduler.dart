import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/services/notifications/local_notifications_initializer.dart';
import '../../domain/models/vehicle_document.dart';

/// Recordatorios locales de vencimiento (D6): 30, 7 y 1 día antes, sin
/// depender de red ni de servidor propio. La zona horaria (`tz.local`) y el
/// plugin ya quedaron inicializados por `LocalNotificationsInitializer` en
/// `main.dart`, antes de que se resuelva este servicio por DI — ver ahí para
/// la resolución de la zona real del dispositivo con fallback a Bogotá.
@lazySingleton
class DocumentReminderScheduler {
  DocumentReminderScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const List<int> daysBeforeExpiry = [30, 7, 1];
  static const int _reminderHour = 9;

  /// Diálogo nativo del permiso de notificaciones, siempre precedido por el
  /// aviso propio (`NotificationPermissionSheet`).
  Future<bool> requestPermission() =>
      LocalNotificationsInitializer.requestPermission();

  /// Cancela lo anterior y programa de nuevo desde la fecha de vencimiento
  /// actual. Se usa al subir, reemplazar o reactivar el recordatorio.
  Future<void> scheduleForDocument(
    String vehicleId,
    VehicleDocument document, {
    required String vehicleName,
    required String title,
    required String Function(int daysBefore) bodyBuilder,
  }) async {
    await cancelForDocument(vehicleId, document.kind);
    if (!document.reminderEnabled) return;

    final now = DateTime.now();
    for (final daysBefore in daysBeforeExpiry) {
      final fireDate = DateTime(
        document.expiryDate.year,
        document.expiryDate.month,
        document.expiryDate.day - daysBefore,
        _reminderHour,
      );
      if (fireDate.isBefore(now)) continue;

      await _plugin.zonedSchedule(
        reminderId(vehicleId, document.kind, daysBefore),
        title,
        bodyBuilder(daysBefore),
        tz.TZDateTime.from(fireDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('document_reminders', 'Documentos'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelForDocument(String vehicleId, DocumentKind kind) async {
    for (final daysBefore in daysBeforeExpiry) {
      await _plugin.cancel(reminderId(vehicleId, kind, daysBefore));
    }
  }

  /// Cancela SOAT y RTM de una moto: se usa al borrarla o archivarla, para
  /// que ningún recordatorio sobreviva a una moto que ya no existe.
  Future<void> cancelAllForVehicle(String vehicleId) async {
    for (final kind in DocumentKind.values) {
      await cancelForDocument(vehicleId, kind);
    }
  }

  /// Id estable y determinista (sin colisiones entre motos/documentos) para
  /// poder cancelar exactamente la notificación programada.
  static int reminderId(String vehicleId, DocumentKind kind, int daysBefore) {
    return Object.hash(vehicleId, kind, daysBefore) & 0x7fffffff;
  }
}
