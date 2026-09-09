import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;

/// Inicializa `flutter_local_notifications` y la base de datos de zonas
/// horarias. Se llama una sola vez desde `main.dart`, antes de
/// `configureDependencies` (el plugin se resuelve luego vía DI).
///
/// Pendiente conocido: sin `flutter_native_timezone` (fuera de alcance de
/// esta fase), la zona local de `timezone` queda en UTC por defecto. Con
/// Colombia en UTC-5 fijo todo el año (sin horario de verano), el efecto es
/// que el recordatorio programado puede llegar hasta 5 horas antes/después
/// de la medianoche local del día elegido — nunca en un día distinto salvo
/// que la hora programada caiga en esa ventana. Aceptable para un
/// recordatorio de "próximo servicio", no para un aviso a hora exacta.
abstract final class LocalNotificationsInitializer {
  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }
}
