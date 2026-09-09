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
  String get maintenance_empty_title => 'Registra tu primer mantenimiento';

  @override
  String get maintenance_empty_body =>
      'Lleva el kilometraje, los cambios de aceite y los recordatorios de tus motos en un solo lugar.';

  @override
  String get maintenance_empty_action => 'Registrar mantenimiento';

  @override
  String get maintenance_page_title => 'Mantenimiento';

  @override
  String get maintenance_filter_action_label => 'Filtrar por estado';

  @override
  String get maintenance_filter_all => 'Todas';

  @override
  String get maintenance_section_agenda => 'PRÓXIMOS';

  @override
  String get maintenance_section_history => 'HISTORIAL';

  @override
  String get maintenance_section_reminder => 'RECORDATORIO';

  @override
  String get maintenance_urgency_overdue => 'Vencido';

  @override
  String get maintenance_urgency_due_soon => 'Este mes';

  @override
  String get maintenance_urgency_upcoming => 'Más adelante';

  @override
  String maintenance_value_km(String value) {
    return '$value km';
  }

  @override
  String maintenance_value_days(String value) {
    return '$value días';
  }

  @override
  String get maintenance_fab_label => 'Registrar mantenimiento';

  @override
  String get maintenance_filter_sheet_title => 'Filtrar por estado';

  @override
  String get maintenance_filter_status_all => 'Todos';

  @override
  String get maintenance_filter_status_overdue => 'Vencidos';

  @override
  String get maintenance_filter_status_due_soon => 'Este mes';

  @override
  String get maintenance_filter_status_upcoming => 'Al día';

  @override
  String get maintenance_error_title => 'No pudimos cargar tu mantenimiento';

  @override
  String get maintenance_offline_body =>
      'No pudimos cargar tu mantenimiento. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get maintenance_detail_field_workshop => 'Taller';

  @override
  String get maintenance_detail_field_cost => 'Costo';

  @override
  String get maintenance_detail_field_note => 'Nota';

  @override
  String maintenance_detail_reminder_next_km(String value) {
    return 'Próximo a los $value km';
  }

  @override
  String maintenance_detail_reminder_next_date(String date) {
    return 'O el $date · toca para cambiar';
  }

  @override
  String get maintenance_detail_previous_section => 'ANTES, EN ESTA MOTO';

  @override
  String maintenance_detail_duration(String value) {
    return 'Duró $value km';
  }

  @override
  String maintenance_detail_see_more(int count) {
    return 'Ver $count más';
  }

  @override
  String get maintenance_detail_see_less => 'Ver menos';

  @override
  String maintenance_detail_average(String value) {
    return 'Te dura $value km en promedio.';
  }

  @override
  String get maintenance_detail_menu_semantic => 'Más acciones';

  @override
  String get maintenance_actions_sheet_edit => 'Editar registro';

  @override
  String get maintenance_actions_sheet_delete => 'Eliminar registro';

  @override
  String get maintenance_delete_confirm_title => '¿Eliminar este registro?';

  @override
  String maintenance_delete_confirm_body(String type, String date) {
    return 'Se borra $type del $date, y con él el recordatorio del próximo cambio. No se puede deshacer.';
  }

  @override
  String get maintenance_delete_confirm_action => 'Sí, eliminar';

  @override
  String get maintenance_delete_confirm_cancel => 'Cancelar';

  @override
  String get maintenance_register_title => 'Registrar mantenimiento';

  @override
  String get maintenance_edit_title => 'Editar mantenimiento';

  @override
  String maintenance_register_step_label(int step) {
    return 'Paso $step de 3';
  }

  @override
  String get maintenance_register_step1_question =>
      '¿Qué mantenimiento registras?';

  @override
  String get maintenance_register_step1_other_question =>
      '¿Qué mantenimiento fue?';

  @override
  String get maintenance_type_oil_change => 'Cambio de aceite y filtro';

  @override
  String get maintenance_type_tire_change => 'Cambio de llanta';

  @override
  String get maintenance_type_brake_pads => 'Pastillas de freno';

  @override
  String get maintenance_type_drive_kit => 'Kit de arrastre';

  @override
  String get maintenance_type_general_check => 'Revisión general';

  @override
  String get maintenance_type_other => 'Otro';

  @override
  String get maintenance_type_other_field_label => 'Tipo de mantenimiento';

  @override
  String get maintenance_type_other_field_hint =>
      'Escribe el nombre del mantenimiento, por ejemplo: \"Cambio de bujías\".';

  @override
  String get maintenance_register_step2_question => '¿Cuál es el kilometraje?';

  @override
  String get maintenance_register_odometer_suffix => 'km';

  @override
  String maintenance_register_odometer_helper_will_update(
    String current,
    String value,
  ) {
    return 'Ahora tiene $current km. Con esto tu odómetro quedaría actualizado a $value km.';
  }

  @override
  String maintenance_register_odometer_helper_past_record(String current) {
    return 'Es un registro anterior: tu moto ya va en $current km y el odómetro no cambia.';
  }

  @override
  String get maintenance_register_step3_question => '¿Algún detalle más?';

  @override
  String get maintenance_register_step3_subtitle =>
      'Todo esto es opcional. Puedes guardar así.';

  @override
  String get maintenance_field_date => 'Fecha';

  @override
  String get maintenance_field_workshop => 'Taller o quién lo hizo';

  @override
  String get maintenance_field_cost => 'Costo';

  @override
  String get maintenance_field_note => 'Nota';

  @override
  String get maintenance_reminder_toggle_label => 'Avisarme del próximo';

  @override
  String get maintenance_reminder_toggle_off => 'Opcional. Está apagado.';

  @override
  String maintenance_reminder_toggle_on(String summary) {
    return '$summary · toca para cambiar';
  }

  @override
  String maintenance_reminder_km_only(String km) {
    return 'Cada $km km';
  }

  @override
  String maintenance_reminder_months_only(String months) {
    return 'Cada $months meses';
  }

  @override
  String maintenance_reminder_both(String km, String months) {
    return 'Cada $km km o $months meses';
  }

  @override
  String get maintenance_interval_sheet_title => '¿Cada cuánto te aviso?';

  @override
  String maintenance_interval_sheet_subtitle(String type, String vehicle) {
    return '$type · $vehicle';
  }

  @override
  String get maintenance_interval_km_label => 'Avísame cada';

  @override
  String get maintenance_interval_km_suffix => 'km';

  @override
  String get maintenance_interval_months_label => 'O cada';

  @override
  String get maintenance_interval_months_suffix => 'meses';

  @override
  String get maintenance_interval_helper =>
      'Con uno basta. Si pones los dos, te avisamos con el que se cumpla primero.';

  @override
  String get maintenance_action_next => 'Siguiente';

  @override
  String get maintenance_action_save => 'Guardar';

  @override
  String get maintenance_action_saving => 'Guardando…';

  @override
  String get maintenance_save_error_title => 'No pudimos guardar';

  @override
  String get maintenance_save_error_body =>
      'Revisa tu conexión e inténtalo de nuevo. Tus datos siguen aquí.';

  @override
  String get maintenance_notification_permission_title =>
      'Activa los avisos de mantenimiento';

  @override
  String get maintenance_notification_permission_body =>
      'Te avisamos en el celular cuando se acerque el próximo servicio. Puedes desactivarlo cuando quieras.';

  @override
  String get maintenance_notification_permission_action => 'Activar avisos';

  @override
  String get maintenance_notification_permission_dismiss => 'Ahora no';

  @override
  String get maintenance_notification_title => 'Se acerca un mantenimiento';

  @override
  String maintenance_notification_body(String type, String vehicle) {
    return '$type de tu $vehicle.';
  }

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
