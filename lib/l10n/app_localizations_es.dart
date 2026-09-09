// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get common_retry => 'Reintentar';

  @override
  String get common_error_title => 'No pudimos cargar esto';

  @override
  String get common_error_body =>
      'Algo falló de nuestro lado. Inténtalo de nuevo.';

  @override
  String get common_empty_title => 'Todavía no hay nada aquí';

  @override
  String get common_offline_title => 'Sin conexión';

  @override
  String get common_offline_body =>
      'Revisa tu conexión e inténtalo de nuevo. Rideglory necesita internet para esto.';

  @override
  String get common_location_permission_title => 'Necesitamos tu ubicación';

  @override
  String get common_location_permission_body =>
      'Sin este permiso no podemos mostrarte esto. Actívalo desde los ajustes del sistema.';

  @override
  String get common_location_permission_action => 'Dar permiso';

  @override
  String get common_no_gps_title => 'Tu GPS está apagado';

  @override
  String get common_no_gps_body =>
      'Actívalo para que podamos ubicarte con precisión.';

  @override
  String get common_no_gps_action => 'Activar GPS';

  @override
  String get maintenance_tab_label => 'MANTENIMIENTO';

  @override
  String get maintenance_empty_title => 'Aún no registras mantenimientos';

  @override
  String get maintenance_empty_body =>
      'Cuando registres el primero, aquí verás tu historial y lo que se viene.';

  @override
  String get events_tab_label => 'EVENTOS';

  @override
  String get events_empty_title => 'No hay rodadas por ahora';

  @override
  String get events_empty_body =>
      'Cuando alguien organice una rodada, aparecerá aquí.';

  @override
  String get garage_tab_label => 'GARAJE';

  @override
  String get garage_empty_title => 'Tu garaje está vacío';

  @override
  String get garage_empty_body =>
      'Agrega tu primera moto para llevar su mantenimiento y documentos.';

  @override
  String get profile_tab_label => 'PERFIL';

  @override
  String get profile_empty_title => 'Tu perfil';

  @override
  String get profile_empty_body =>
      'Aquí vas a gestionar tus datos, tu contacto de emergencia y tu cuenta.';

  @override
  String get welcome_title => 'Rideglory';

  @override
  String get welcome_subtitle =>
      'Tu garaje, tu mantenimiento y tus rodadas en un solo lugar.';

  @override
  String get welcome_continue_email => 'Continuar con correo';
}
