import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Inicializa `flutter_local_notifications` y la base de datos de zonas
/// horarias. Se llama una sola vez desde `main.dart`, antes de
/// `configureDependencies` (el plugin se resuelve luego vía DI).
///
/// La zona local se resuelve con `flutter_timezone` (IANA del dispositivo).
/// Si falla o devuelve algo que `timezone` no reconoce, cae a
/// `America/Bogota`: Colombia está en UTC-5 fijo todo el año, sin horario
/// de verano, así que es un fallback seguro para el público de la app.
abstract final class LocalNotificationsInitializer {
  static const String _fallbackLocation = 'America/Bogota';

  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(await _resolveLocalTimeZoneName()));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  /// Diálogo nativo del permiso de notificaciones. Nunca se llama directo
  /// desde presentación: siempre después del aviso propio en
  /// `NotificationPermissionSheet` (regla de producto D6).
  static Future<bool> requestPermission() async {
    final androidGranted = await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final iosGranted = await plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (androidGranted ?? iosGranted) ?? true;
  }

  static Future<String> _resolveLocalTimeZoneName() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final name = timezoneInfo.identifier;
      tz.getLocation(name);
      return name;
    } catch (error, stackTrace) {
      developer.log(
        'No se pudo resolver la zona horaria del dispositivo, usando '
        '$_fallbackLocation.',
        name: 'LocalNotificationsInitializer',
        error: error,
        stackTrace: stackTrace,
      );
      return _fallbackLocation;
    }
  }
}
