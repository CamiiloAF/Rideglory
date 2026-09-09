import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/vehicle_document.dart';

/// Recordatorios locales de vencimiento (D6): 30, 7 y 1 día antes, sin
/// depender de red ni de servidor propio. Colombia no tiene horario de
/// verano y es un único huso (`America/Bogota`), así que se fija ese
/// `Location` en vez de resolver el del dispositivo.
@lazySingleton
class DocumentReminderScheduler {
  DocumentReminderScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const List<int> daysBeforeExpiry = [30, 7, 1];
  static const int _reminderHour = 9;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Bogota'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

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

  /// Id estable y determinista (sin colisiones entre motos/documentos) para
  /// poder cancelar exactamente la notificación programada.
  static int reminderId(String vehicleId, DocumentKind kind, int daysBefore) {
    return Object.hash(vehicleId, kind, daysBefore) & 0x7fffffff;
  }
}
