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

  @override
  String get garage_title => 'Mi garaje';

  @override
  String get garage_add_vehicle_button => 'Agregar moto';

  @override
  String get garage_add_vehicle_button_short => 'Agregar moto';

  @override
  String get garage_add_vehicle_title => 'Agregar moto';

  @override
  String get garage_edit_vehicle_title => 'Editar moto';

  @override
  String get garage_error_title => 'No pudimos cargar tu garaje';

  @override
  String get garage_plate_question => '¿Cuál es la placa?';

  @override
  String get garage_plate_hint =>
      'Es lo único que necesitamos para empezar. Lo demás lo enseguidas.';

  @override
  String get garage_plate_field_label => 'Placa';

  @override
  String get garage_plate_helper =>
      'Formato de moto: tres letras, dos números y una letra.';

  @override
  String get garage_plate_invalid_error =>
      'Esa placa no parece de moto. Van tres letras, dos números y una letra, por ejemplo ABC12D.';

  @override
  String get garage_continue_button => 'Continuar';

  @override
  String get garage_change_plate_button => 'Cambiar';

  @override
  String get garage_brand_field_label => 'Marca';

  @override
  String get garage_model_field_label => 'Línea';

  @override
  String get garage_year_field_label => 'Año';

  @override
  String get garage_engine_cc_field_label => 'Cilindraje';

  @override
  String get garage_engine_cc_suffix => 'cc';

  @override
  String get garage_mileage_today_label => 'Kilometraje de hoy';

  @override
  String get garage_mileage_current_label => 'Kilometraje actual';

  @override
  String get garage_mileage_suffix => 'km';

  @override
  String get garage_mileage_create_helper =>
      'Desde acá arrancamos tu odómetro.';

  @override
  String get garage_mileage_edit_helper =>
      'Se actualiza solo cuando registras un mantenimiento.';

  @override
  String garage_mileage_value(String km) {
    return '$km km';
  }

  @override
  String get garage_photo_add_label => 'Agregar foto (opcional)';

  @override
  String get garage_photo_selected_label => 'Foto lista';

  @override
  String get garage_photo_add_hint => 'Puedes agregarla o cambiarla después.';

  @override
  String get garage_save_vehicle_button => 'Guardar moto';

  @override
  String get garage_save_changes_button => 'Guardar cambios';

  @override
  String get garage_saving_label => 'Guardando...';

  @override
  String get garage_save_error_title => 'No pudimos guardar tu moto';

  @override
  String get garage_save_error_body =>
      'Revisa tu conexión e inténtalo de nuevo. Tus datos siguen aquí.';

  @override
  String get garage_main_vehicle_label => 'Moto principal';

  @override
  String get garage_delete_vehicle_button => 'Eliminar moto';

  @override
  String get garage_delete_confirm_title => '¿Eliminar esta moto?';

  @override
  String get garage_delete_confirm_body =>
      'Se borran también sus mantenimientos y documentos. No se puede deshacer.';

  @override
  String get garage_delete_cancel => 'Cancelar';

  @override
  String get garage_delete_confirm_action => 'Eliminar';

  @override
  String get garage_archive_vehicle_button => 'Archivar moto';

  @override
  String get garage_unarchive_vehicle_button => 'Restaurar moto';

  @override
  String get garage_documents_section_title => 'DOCUMENTOS';

  @override
  String get garage_document_kind_soat => 'SOAT';

  @override
  String get garage_document_kind_rtm => 'Tecno';

  @override
  String garage_document_alert_expired(String kind) {
    return '$kind · vencido';
  }

  @override
  String garage_document_alert_expiring(String kind, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return '$kind · $_temp0';
  }

  @override
  String get garage_brand_picker_title => 'Marca';

  @override
  String get garage_brand_search_label => 'Buscar marca';

  @override
  String get garage_brand_search_empty_title => 'No encontramos esa marca';

  @override
  String get garage_brand_search_empty => 'Prueba con otro nombre.';

  @override
  String get documents_soat_title => 'SOAT';

  @override
  String get documents_rtm_title => 'Tecnomecánica';

  @override
  String documents_not_uploaded_title(String kind) {
    return 'Todavía no has subido tu $kind';
  }

  @override
  String get documents_not_uploaded_body =>
      'Sácale una foto y en el teléfono la muestras aunque no tengas señal.';

  @override
  String get documents_not_uploaded_short => 'Sin subir';

  @override
  String documents_upload_button(String kind) {
    return 'Subir $kind';
  }

  @override
  String get documents_privacy_note =>
      'Queda privado: solo tú lo ves hasta que decidas compartirlo.';

  @override
  String get documents_offline_banner_title => 'Estás sin conexión';

  @override
  String get documents_offline_banner_body =>
      'Tu documento se abre igual: está guardado en el teléfono.';

  @override
  String get documents_saved_locally_note =>
      'Guardado en tu teléfono: se abre sin señal.';

  @override
  String get documents_share_button => 'Compartir';

  @override
  String get documents_replace_button => 'Reemplazar documento';

  @override
  String documents_expires_on(String date) {
    return 'Vence el $date';
  }

  @override
  String get documents_status_valid => 'Vigente';

  @override
  String get documents_status_expiring_soon => 'Vence pronto';

  @override
  String get documents_status_expired => 'Vencido';

  @override
  String get documents_upload_origin_title => '¿De dónde lo sacamos?';

  @override
  String get documents_upload_origin_subtitle =>
      'Elige cómo quieres agregar el documento.';

  @override
  String get documents_origin_camera => 'Tomar foto';

  @override
  String get documents_origin_gallery => 'Elegir de la galería';

  @override
  String get documents_origin_pdf => 'Subir un PDF';

  @override
  String get documents_confirm_question => '¿Se ve completo y legible?';

  @override
  String get documents_policy_number_label => 'Número de póliza';

  @override
  String get documents_issuer_label => 'Aseguradora';

  @override
  String get documents_autofilled_hint =>
      'Lo tomamos de la foto. Revisa que esté bien.';

  @override
  String get documents_expiry_date_label => '¿Cuándo vence?';

  @override
  String get documents_expiry_date_helper =>
      'Te avisamos en el teléfono cuando se acerque.';

  @override
  String get documents_pdf_preview_label => 'Documento PDF';

  @override
  String get documents_save_button => 'Guardar documento';

  @override
  String get documents_saving_label => 'Guardando...';

  @override
  String get documents_save_error_title => 'No pudimos guardar tu documento';

  @override
  String get documents_save_error_body =>
      'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get documents_retake_button => 'Repetir la foto';

  @override
  String documents_reminder_body(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Vence en $days días',
      one: 'Vence mañana',
    );
    return '$_temp0';
  }

  @override
  String get auth_welcome_title => 'Rideglory';

  @override
  String get auth_welcome_headline =>
      'Lleva la cuenta de tu moto sin acordarte de nada';

  @override
  String get auth_welcome_feature_maintenance_title =>
      'Cuánto te duró cada pieza';

  @override
  String get auth_welcome_feature_maintenance_body =>
      'Registras el cambio con el kilometraje y la app te dice cuánto duró la anterior.';

  @override
  String get auth_welcome_feature_garage_title => 'Tus motos en un solo lugar';

  @override
  String get auth_welcome_feature_garage_body =>
      'Kilometraje, mantenimientos y documentos de cada moto.';

  @override
  String get auth_welcome_feature_documents_title => 'El SOAT abre sin señal';

  @override
  String get auth_welcome_feature_documents_body =>
      'Queda guardado en el teléfono para mostrarlo en un retén.';

  @override
  String get auth_welcome_continue_google => 'Continuar con Google';

  @override
  String get auth_welcome_continue_apple => 'Continuar con Apple';

  @override
  String get auth_welcome_continue_email => 'Continuar con correo';

  @override
  String get auth_welcome_legal =>
      'Al continuar aceptas los Términos y la Política de privacidad.';

  @override
  String get auth_email_login_title => 'Entrar con correo';

  @override
  String get auth_email_field_label => 'Correo';

  @override
  String get auth_password_field_label => 'Contraseña';

  @override
  String get auth_password_show_action => 'Ver';

  @override
  String get auth_password_hide_action => 'Ocultar';

  @override
  String get auth_forgot_password_link => '¿Olvidaste tu contraseña?';

  @override
  String get auth_sign_in_button => 'Iniciar sesión';

  @override
  String get auth_create_account_link => 'Crear una cuenta nueva';

  @override
  String get auth_have_account_link => 'Ya tengo una cuenta';

  @override
  String get auth_error_banner_title => 'No pudimos iniciar sesión';

  @override
  String get auth_password_error_helper => 'Revisa tu contraseña.';

  @override
  String get auth_register_title => 'Crear cuenta';

  @override
  String get auth_register_name_label => 'Nombre';

  @override
  String get auth_register_button => 'Crear cuenta';

  @override
  String get auth_forgot_title => 'Recuperar contraseña';

  @override
  String get auth_forgot_heading => 'Te mandamos un enlace';

  @override
  String get auth_forgot_body =>
      'Escribe el correo con el que te registraste y te enviamos un enlace para poner una contraseña nueva.';

  @override
  String get auth_forgot_send_button => 'Enviar enlace';

  @override
  String get auth_forgot_sent_title => 'Enlace enviado';

  @override
  String get auth_forgot_sent_body =>
      'Revisa tu correo, incluida la carpeta de spam.';

  @override
  String get auth_field_required => 'Este campo es obligatorio.';

  @override
  String get auth_email_invalid => 'Escribe un correo válido.';

  @override
  String get auth_password_too_short =>
      'Usa una contraseña de al menos 6 caracteres.';

  @override
  String get auth_error_invalid_credentials =>
      'El correo o la contraseña no coinciden. Revísalos e inténtalo otra vez.';

  @override
  String get auth_error_email_already_registered =>
      'Ese correo ya tiene una cuenta. Intenta iniciar sesión.';

  @override
  String get auth_error_weak_password =>
      'Usa una contraseña de al menos 6 caracteres.';

  @override
  String get auth_error_user_not_found =>
      'No encontramos una cuenta con ese correo.';

  @override
  String get auth_error_provider_cancelled => 'Cancelaste el inicio de sesión.';

  @override
  String get auth_error_offline =>
      'No hay conexión. Revisa tu internet e inténtalo de nuevo.';

  @override
  String get auth_error_unknown => 'Algo falló. Inténtalo de nuevo.';

  @override
  String get profile_title => 'Perfil';

  @override
  String get profile_settings_icon_label => 'Ajustes';

  @override
  String get profile_section_account => 'CUENTA';

  @override
  String get profile_field_name => 'Nombre';

  @override
  String get profile_field_email => 'Correo';

  @override
  String get profile_section_emergency => 'EN CASO DE EMERGENCIA';

  @override
  String get profile_emergency_contact_label => 'Contacto de emergencia';

  @override
  String get profile_emergency_not_configured => 'Sin configurar';

  @override
  String get profile_emergency_add_action => 'Agregar';

  @override
  String get profile_section_notifications => 'NOTIFICACIONES Y DATOS';

  @override
  String get profile_notifications_label => 'Notificaciones';

  @override
  String get profile_share_usage_label => 'Compartir datos de uso';

  @override
  String get profile_share_usage_subtitle => 'Nos ayuda a mejorar la app';

  @override
  String get profile_section_legal => 'LEGAL';

  @override
  String get profile_terms => 'Términos y condiciones';

  @override
  String get profile_privacy => 'Política de privacidad';

  @override
  String get profile_my_consents => 'Mis consentimientos';

  @override
  String get profile_sign_out => 'Cerrar sesión';

  @override
  String get profile_delete_account => 'Borrar mi cuenta';

  @override
  String get profile_emergency_banner_title => 'En caso de emergencia';

  @override
  String get profile_emergency_banner_body =>
      'Todavía no tienes contacto de emergencia. Es el número al que llamarían tus compañeros si algo pasa en una rodada.';

  @override
  String get profile_emergency_add_contact_cta => 'Agregar contacto';

  @override
  String get profile_my_vehicles_title => 'MIS MOTOS';

  @override
  String get profile_settings_group_title => 'AJUSTES';

  @override
  String get profile_privacy_and_consents => 'Privacidad y consentimientos';

  @override
  String get profile_load_error_title => 'No pudimos cargar tu perfil';

  @override
  String get profile_load_error_body =>
      'Algo falló de nuestro lado. Inténtalo de nuevo.';

  @override
  String get profile_offline_title => 'Sin conexión';

  @override
  String get profile_offline_body =>
      'No pudimos cargar el perfil. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get profile_edit_title => 'Editar perfil';

  @override
  String get profile_field_phone => 'Teléfono';

  @override
  String get profile_field_birth_date => 'Fecha de nacimiento';

  @override
  String get profile_field_city => 'Ciudad';

  @override
  String get profile_field_eps => 'EPS';

  @override
  String get profile_field_insurance => 'Seguro médico';

  @override
  String get profile_field_blood_type => 'Tipo de sangre';

  @override
  String get profile_blood_type_placeholder => 'Selecciona';

  @override
  String get profile_blood_type_o_positive => 'O+';

  @override
  String get profile_blood_type_o_negative => 'O-';

  @override
  String get profile_blood_type_a_positive => 'A+';

  @override
  String get profile_blood_type_a_negative => 'A-';

  @override
  String get profile_blood_type_b_positive => 'B+';

  @override
  String get profile_blood_type_b_negative => 'B-';

  @override
  String get profile_blood_type_ab_positive => 'AB+';

  @override
  String get profile_blood_type_ab_negative => 'AB-';

  @override
  String get profile_save_button => 'Guardar cambios';

  @override
  String get profile_update_success => 'Perfil actualizado.';

  @override
  String get profile_update_error =>
      'No pudimos guardar los cambios. Inténtalo de nuevo.';

  @override
  String get profile_emergency_page_title => 'Contacto de emergencia';

  @override
  String get profile_emergency_info_title => 'Para qué sirve';

  @override
  String get profile_emergency_info_body =>
      'Es el número que verían tus compañeros de rodada si algo te pasa. Se guarda en tu teléfono para tenerlo a mano.';

  @override
  String get profile_emergency_field_name => 'Nombre';

  @override
  String get profile_emergency_field_phone => 'Teléfono';

  @override
  String get profile_emergency_field_relationship => 'Parentesco';

  @override
  String get profile_emergency_consent_note =>
      'Avísale a esta persona que la registraste. Puedes cambiarla o borrarla cuando quieras.';

  @override
  String get profile_emergency_save_button => 'Guardar contacto';

  @override
  String get profile_emergency_save_success =>
      'Contacto de emergencia guardado.';

  @override
  String get profile_emergency_save_error =>
      'No pudimos guardar el contacto. Inténtalo de nuevo.';

  @override
  String get profile_consents_title => 'Mis consentimientos';

  @override
  String get profile_consents_empty_title => 'Sin consentimientos registrados';

  @override
  String get profile_consents_empty_body =>
      'Aquí vas a ver cada consentimiento que aceptaste, con fecha y versión.';

  @override
  String get profile_consent_kind_risk_acceptance => 'Aceptación de riesgo';

  @override
  String get profile_consent_kind_medical_consent => 'Consentimiento médico';

  @override
  String get profile_consent_kind_terms => 'Términos y condiciones';

  @override
  String profile_consent_version_label(String version) {
    return 'Versión $version';
  }

  @override
  String get profile_delete_step1_title => 'Borrar mi cuenta';

  @override
  String get profile_delete_headline =>
      'Esto borra tu cuenta y todo lo que has guardado';

  @override
  String get profile_delete_subtext =>
      'No es cerrar sesión: los datos se eliminan y no se pueden recuperar.';

  @override
  String profile_delete_item_vehicles(int count) {
    return '$count motos de tu garaje';
  }

  @override
  String profile_delete_item_maintenances(int count) {
    return '$count mantenimientos registrados';
  }

  @override
  String profile_delete_item_documents(int count) {
    return '$count documentos guardados (SOAT y tecnomecánica)';
  }

  @override
  String get profile_delete_item_registrations => 'Tus inscripciones a rodadas';

  @override
  String get profile_delete_item_profile =>
      'Tu perfil y tu contacto de emergencia';

  @override
  String get profile_delete_just_logout_title =>
      '¿Solo quieres salir de la app?';

  @override
  String get profile_delete_just_logout_body =>
      'Cierra sesión desde el perfil: tus datos se quedan como están.';

  @override
  String get profile_delete_continue_button => 'Continuar con el borrado';

  @override
  String get profile_delete_cancel_button => 'Mejor no, cancelar';

  @override
  String get profile_delete_confirm_title => '¿Borramos tu cuenta?';

  @override
  String profile_delete_confirm_body(
    int vehicles,
    int maintenances,
    int documents,
  ) {
    return 'Se eliminan tus $vehicles motos, $maintenances mantenimientos y $documents documentos. Esta acción no se puede deshacer.';
  }

  @override
  String get profile_delete_confirm_checkbox =>
      'Entiendo que no se puede recuperar';

  @override
  String get profile_delete_confirm_button => 'Sí, borrar mi cuenta';

  @override
  String get profile_delete_confirm_cancel => 'Cancelar';

  @override
  String get profile_delete_progress_title => 'Borrando tu cuenta...';

  @override
  String get profile_delete_progress_body =>
      'No cierres la app. Esto toma unos segundos.';

  @override
  String get profile_delete_blocked_title =>
      'Todavía no puedes borrar la cuenta';

  @override
  String get profile_delete_blocked_body =>
      'Eres el organizador de una rodada que aún no termina. Si borras tu cuenta ahora, quienes se inscribieron se quedan sin quién responda.';

  @override
  String get profile_delete_blocked_what_title => 'Para poder borrarla';

  @override
  String get profile_delete_blocked_option_cancel_event =>
      'Cancela la rodada, o';

  @override
  String get profile_delete_blocked_option_wait =>
      'espera a que termine y vuelve acá';

  @override
  String get profile_delete_blocked_view_event => 'Ver la rodada';

  @override
  String get profile_delete_blocked_back_to_profile => 'Volver al perfil';

  @override
  String get profile_delete_error_title => 'No pudimos borrar tu cuenta';

  @override
  String get profile_delete_error_body =>
      'Algo falló de nuestro lado. Tu cuenta sigue activa. Inténtalo de nuevo.';
}
