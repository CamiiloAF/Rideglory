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
  String get maintenance_no_vehicles_title => 'Primero registra una moto';

  @override
  String get maintenance_no_vehicles_body =>
      'El mantenimiento se lleva por moto: agrega la tuya al garaje para empezar a registrar.';

  @override
  String get maintenance_no_vehicles_action => 'Agregar moto';

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
  String get maintenance_delete_error_title =>
      'No pudimos eliminar el mantenimiento';

  @override
  String get maintenance_delete_error_body =>
      'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get maintenance_reminder_update_error_title =>
      'No pudimos guardar el recordatorio';

  @override
  String get maintenance_reminder_update_error_body =>
      'Revisa tu conexión e inténtalo de nuevo.';

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
  String get maintenance_reminder_declined_title =>
      'Mantenimiento guardado sin recordatorio';

  @override
  String get maintenance_reminder_declined_body =>
      'Sin el permiso de notificaciones no podemos avisarte del próximo servicio. Puedes activarlo cuando quieras desde el mantenimiento.';

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
  String get documents_reminder_toggle_label => 'Recordarme el vencimiento';

  @override
  String get documents_reminder_toggle_subtitle =>
      'Te avisamos 30, 7 y 1 día antes.';

  @override
  String get notification_permission_sheet_title =>
      'Antes de pedirte el permiso';

  @override
  String get notification_permission_sheet_body =>
      'Rideglory te avisa de vencimientos de documentos y mantenimientos con notificaciones en el teléfono. Ahora te va a aparecer el permiso del sistema — dale \"Permitir\" para no perderte esos avisos.';

  @override
  String get notification_permission_sheet_allow => 'Permitir';

  @override
  String get notification_permission_sheet_cancel => 'Ahora no';

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

  @override
  String get events_list_title => 'Rodadas';

  @override
  String get events_segment_upcoming => 'Próximas';

  @override
  String get events_segment_mine => 'Mías';

  @override
  String get events_list_empty_title => 'Todavía no hay rodadas';

  @override
  String get events_list_empty_body =>
      'Crea la primera o vuelve cuando alguien publique una cerca de ti.';

  @override
  String get events_list_mine_empty_body =>
      'Organiza una rodada o inscríbete a una para verla aquí.';

  @override
  String get events_list_empty_cta => 'Crear rodada';

  @override
  String get events_list_error_title => 'No pudimos cargar las rodadas';

  @override
  String get events_list_offline_body =>
      'No pudimos cargar las rodadas. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get events_card_free => 'Gratis';

  @override
  String get events_difficulty_easy => 'Fácil';

  @override
  String get events_difficulty_medium => 'Media';

  @override
  String get events_difficulty_hard => 'Difícil';

  @override
  String events_detail_meeting_point(String point) {
    return 'Punto de encuentro: $point';
  }

  @override
  String get events_detail_destination_label => 'DESTINO';

  @override
  String get events_detail_route_label => 'RUTA';

  @override
  String get events_detail_open_maps => 'Abrir en Waze/Maps';

  @override
  String events_detail_organizer_prefix(String name) {
    return 'Organiza $name';
  }

  @override
  String events_detail_spots(int approved, int max) {
    return '$approved de $max cupos ocupados';
  }

  @override
  String events_detail_spots_unlimited(int approved) {
    return '$approved inscritos';
  }

  @override
  String get events_detail_register_cta => 'Inscribirme';

  @override
  String get events_detail_registered_badge => 'Inscrito';

  @override
  String get events_detail_cancel_registration_cta => 'Cancelar inscripción';

  @override
  String get events_detail_start_cta => 'Iniciar rodada';

  @override
  String get events_detail_change_route_cta => 'Cambiar ruta';

  @override
  String get events_detail_view_registrants_cta => 'Ver inscritos';

  @override
  String get events_detail_cancel_event_cta => 'Cancelar rodada';

  @override
  String get events_detail_cancel_event_confirm_title =>
      '¿Cancelar esta rodada?';

  @override
  String get events_detail_cancel_event_confirm_body =>
      'Se avisará a todos los inscritos. Esta acción no se puede deshacer.';

  @override
  String get events_detail_cancel_event_confirm_cta => 'Sí, cancelar rodada';

  @override
  String get events_detail_cancel_registration_confirm_title =>
      '¿Cancelar tu inscripción?';

  @override
  String get events_detail_cancel_registration_confirm_body =>
      'Perderás tu cupo en esta rodada.';

  @override
  String get events_detail_confirm_keep => 'No, mantener';

  @override
  String get events_detail_route_changes_title => 'AVISOS DE RUTA';

  @override
  String get events_detail_error_title => 'No pudimos cargar la rodada';

  @override
  String events_detail_start_overdue_title(String time) {
    return 'Tu rodada debía empezar a las $time';
  }

  @override
  String get events_detail_start_overdue_body =>
      'Los inscritos ya están esperando. Inícia la rodada o avísales si se retrasa.';

  @override
  String get events_detail_cancelled_badge => 'Cancelada';

  @override
  String get events_detail_finished_badge => 'Finalizada';

  @override
  String get events_create_title => 'Nueva rodada';

  @override
  String events_create_step_label(int step) {
    return 'Paso $step de 3';
  }

  @override
  String get events_create_step1_title => 'Crea tu rodada';

  @override
  String get events_create_photo_cta => 'Agregar foto de portada';

  @override
  String get events_create_name_label => 'Nombre de la rodada';

  @override
  String get events_create_name_hint =>
      'Por ejemplo: Rodada al Nevado del Ruiz';

  @override
  String get events_create_datetime_label => 'Fecha y hora';

  @override
  String get events_create_datetime_placeholder => 'Selecciona fecha y hora';

  @override
  String get events_create_meeting_point_label => 'Punto de encuentro';

  @override
  String get events_create_meeting_point_hint =>
      'Por ejemplo: Estación Terpel Sur, Autopista Sur';

  @override
  String get events_create_next_cta => 'Siguiente';

  @override
  String get events_create_step2_title => '¿A dónde van?';

  @override
  String get events_create_destination_label => 'Destino';

  @override
  String get events_create_destination_hint =>
      'Busca un lugar o escribe la dirección';

  @override
  String get events_create_route_label => 'Ruta (texto)';

  @override
  String get events_create_route_hint =>
      'Describe el trayecto: por dónde salen, por dónde regresan';

  @override
  String get events_create_difficulty_label => 'Dificultad';

  @override
  String get events_create_step3_title => 'Cupos y precio';

  @override
  String get events_create_spots_label => 'Cupos disponibles';

  @override
  String get events_create_spots_suffix => 'personas';

  @override
  String get events_create_spots_hint =>
      'Máximo de riders que pueden inscribirse';

  @override
  String get events_create_free_label => 'Rodada gratis';

  @override
  String get events_create_free_subtitle => 'Sin costo para los inscritos';

  @override
  String get events_create_price_label => 'Precio (COP)';

  @override
  String get events_create_summary_label => 'RESUMEN';

  @override
  String get events_create_summary_name => 'Nombre';

  @override
  String get events_create_summary_date => 'Fecha';

  @override
  String get events_create_summary_price => 'Precio';

  @override
  String get events_create_publish_cta => 'Publicar rodada';

  @override
  String get events_create_saving => 'Publicando…';

  @override
  String get events_create_saving_subtitle =>
      'Todo esto es opcional. Puedes guardar así.';

  @override
  String get events_create_error_title => 'No pudimos publicar la rodada';

  @override
  String get events_create_error_body =>
      'Revisa tu conexión e inténtalo de nuevo. Tus datos siguen aquí.';

  @override
  String get events_register_title => 'Inscripción';

  @override
  String get events_register_your_data_label => 'TUS DATOS';

  @override
  String get events_register_name_field => 'Nombre';

  @override
  String get events_register_phone_field => 'Teléfono';

  @override
  String get events_register_blood_type_field => 'Tipo de sangre';

  @override
  String get events_register_eps_field => 'EPS';

  @override
  String get events_register_emergency_contact_field =>
      'Contacto de emergencia';

  @override
  String get events_register_not_provided => 'Sin registrar';

  @override
  String get events_register_edit_profile_note =>
      '¿Algo desactualizado? Corrígelo en tu perfil.';

  @override
  String get events_register_permissions_label => 'PERMISOS';

  @override
  String get events_register_share_medical_label =>
      'Compartir mis datos médicos con el organizador';

  @override
  String get events_register_share_medical_subtitle =>
      'Tipo de sangre y EPS, solo si hay una emergencia';

  @override
  String get events_register_allow_contact_label =>
      'Permitir que el organizador me contacte';

  @override
  String get events_register_allow_contact_subtitle =>
      'Solo antes y durante la rodada';

  @override
  String get events_register_risk_label => 'ACEPTACIÓN DE RIESGOS';

  @override
  String get events_register_risk_text =>
      'Entiendo que rodar tiene riesgos y participo bajo mi propia responsabilidad.';

  @override
  String get events_register_risk_terms =>
      'Términos de participación v1.0 · edad mínima 18 años';

  @override
  String get events_register_vehicle_label => 'Moto';

  @override
  String get events_register_no_vehicle_plate => 'Sin placa registrada';

  @override
  String get events_register_confirm_cta => 'Confirmar inscripción';

  @override
  String get events_register_incomplete_title =>
      'Completa tu perfil antes de inscribirte';

  @override
  String get events_register_incomplete_body =>
      'El organizador necesita tu teléfono y tu contacto de emergencia para poder ayudarte en la vía.';

  @override
  String get events_register_incomplete_cta => 'Completar perfil';

  @override
  String get events_register_underage_error =>
      'Debes ser mayor de 18 años para inscribirte a una rodada.';

  @override
  String get events_register_already_registered_error =>
      'Ya estás inscrito en esta rodada.';

  @override
  String get events_register_generic_error =>
      'No pudimos completar tu inscripción. Inténtalo de nuevo.';

  @override
  String events_registrants_title(int approved, int max) {
    return 'Inscritos · $approved/$max';
  }

  @override
  String events_registrants_title_unlimited(int approved) {
    return 'Inscritos · $approved';
  }

  @override
  String get events_registrants_call => 'Llamar';

  @override
  String get events_registrants_call_emergency => 'Contacto de emergencia';

  @override
  String get events_registrants_empty_title => 'Todavía no hay inscritos';

  @override
  String get events_registrants_empty_body =>
      'Cuando alguien se inscriba, lo verás aquí.';

  @override
  String get events_registrants_error_title =>
      'No pudimos cargar los inscritos';

  @override
  String get events_route_change_title => 'Cambiar la ruta';

  @override
  String events_route_change_body(int count) {
    return 'Se lo avisamos a los $count inscritos apenas guardes.';
  }

  @override
  String get events_route_change_field_label => 'Nueva ruta';

  @override
  String get events_route_change_cta => 'Avisar a los inscritos';

  @override
  String get live_notification_title =>
      'Compartiendo tu ubicación con la rodada';

  @override
  String get live_notification_body => 'Toca Detener para dejar de compartir';

  @override
  String get live_notification_stop_button => 'Detener';

  @override
  String get live_ride_error_not_a_participant =>
      'No estás inscrito en esta rodada, así que no podemos mostrarte esto.';

  @override
  String get live_ride_error_event_not_started =>
      'Esta rodada todavía no arrancó.';

  @override
  String get live_ride_error_sos_not_found =>
      'No encontramos esa alerta de SOS.';

  @override
  String get live_ride_error_not_allowed_to_close =>
      'Solo quien lanzó el SOS o el organizador pueden cerrarlo.';

  @override
  String get live_ride_error_location_permission_denied =>
      'Necesitamos tu ubicación para compartirla con la rodada. Actívala desde los ajustes del sistema.';

  @override
  String get live_ride_error_location_service_disabled =>
      'Tu GPS está apagado. Actívalo para compartir tu ubicación.';

  @override
  String get live_ride_error_location_unavailable =>
      'No pudimos obtener tu ubicación. Muévete a un lugar con mejor señal de GPS e inténtalo de nuevo.';

  @override
  String get live_ride_error_offline =>
      'Sin conexión. Revisa tu señal e inténtalo de nuevo.';

  @override
  String get live_ride_error_generic =>
      'Algo falló con la rodada en vivo. Inténtalo de nuevo.';

  @override
  String live_ride_riders_sheet_title(int count) {
    return 'Riders en la rodada ($count)';
  }

  @override
  String get live_ride_share_cta => 'Compartir mi ubicación';

  @override
  String get live_ride_sharing_chip => 'Compartiendo ubicación';

  @override
  String get live_ride_stop_cta => 'Detener';

  @override
  String get live_ride_me_suffix => '(tú)';

  @override
  String get live_ride_leader_suffix => 'Líder';

  @override
  String get live_ride_not_sharing_status => 'No comparte su ubicación';

  @override
  String get live_ride_riders_header_action => 'Ver riders';

  @override
  String live_distance_meters(int meters) {
    return 'A $meters m';
  }

  @override
  String live_distance_km(String km) {
    return 'A $km km';
  }

  @override
  String get live_freshness_now => 'Hace menos de 1 min';

  @override
  String live_freshness_minutes(int minutes) {
    return 'Hace $minutes min';
  }

  @override
  String live_freshness_stale_minutes(int minutes) {
    return 'Sin señal hace $minutes min';
  }

  @override
  String get live_ride_permission_title => 'Necesitamos tu ubicación';

  @override
  String get live_ride_permission_body =>
      'Sin permiso de ubicación no podemos mostrarte la rodada ni compartir la tuya con el grupo. Actívalo en los ajustes del teléfono.';

  @override
  String get live_ride_permission_open_settings_cta => 'Abrir ajustes';

  @override
  String get live_ride_permission_retry_cta => 'Ya lo activé, reintentar';

  @override
  String get live_ride_no_gps_title => 'No encontramos señal de GPS';

  @override
  String get live_ride_no_gps_body =>
      'Verifica que el GPS de tu teléfono esté encendido. En túneles o zonas de montaña puede tardar un poco en ubicarte.';

  @override
  String get live_ride_no_gps_open_settings_cta => 'Abrir ajustes de ubicación';

  @override
  String get live_ride_no_gps_retry_cta => 'Reintentar';

  @override
  String get live_ride_offline_body =>
      'No pudimos actualizar la rodada en vivo. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get live_ride_error_title => 'Algo falló';

  @override
  String get live_ride_finished_title => 'La rodada terminó';

  @override
  String get live_ride_finished_body =>
      'Se dejó de compartir tu ubicación con el grupo.';

  @override
  String get live_ride_finished_cta => 'Volver al evento';

  @override
  String get live_ride_finished_status_line =>
      'La rodada terminó. Se dejó de compartir tu ubicación.';

  @override
  String get live_ride_finished_sos_title => 'Tu alerta SOS sigue activa';

  @override
  String get live_ride_finished_sos_body =>
      'El grupo la sigue viendo aunque la rodada haya terminado. Ciérrala solo cuando estés bien.';

  @override
  String get live_ride_consent_title => 'Compartir tu ubicación con el grupo';

  @override
  String get live_ride_consent_row_participants =>
      'Solo la ven los inscritos en esta rodada.';

  @override
  String get live_ride_consent_row_duration =>
      'Solo se comparte mientras la rodada está en curso.';

  @override
  String get live_ride_consent_row_stop =>
      'Para cuando quieras: botón Detener y notificación persistente.';

  @override
  String get live_ride_consent_allow_cta => 'Permitir';

  @override
  String get live_ride_consent_dismiss_cta => 'Ahora no';

  @override
  String get live_ride_consent_always_title =>
      'Compartir tu ubicación todo el tiempo';

  @override
  String get live_ride_consent_always_row_notification =>
      'Verás una notificación mientras compartas, para saber que sigue activa.';

  @override
  String get live_ride_consent_always_row_lock =>
      'Sin este permiso, tu posición deja de actualizarse al bloquear la pantalla.';

  @override
  String get live_ride_consent_always_allow_cta => 'Permitir todo el tiempo';

  @override
  String get live_ride_background_permission_banner =>
      'Sin permiso de ubicación en segundo plano: si bloqueas la pantalla, se deja de compartir.';

  @override
  String get sos_button_label => 'SOS';

  @override
  String get sos_confirm_title => '¿Pedir ayuda al grupo?';

  @override
  String get sos_confirm_body =>
      'Avisaremos a los riders de esta rodada con tu ubicación. No llama a emergencias.';

  @override
  String get sos_confirm_hold_label => 'Mantén pulsado para enviar';

  @override
  String get sos_confirm_cancel_cta => 'Cancelar';

  @override
  String get sos_active_header_title => 'SOS activo';

  @override
  String get sos_pending_title => 'Alerta pendiente';

  @override
  String get sos_pending_body =>
      'Sin señal. Tu alerta se enviará al recuperar cobertura.';

  @override
  String get sos_pending_chip => 'Enviando cuando haya señal';

  @override
  String get sos_sending_title => 'Enviando tu alerta';

  @override
  String get sos_confirmed_title => 'El grupo ya sabe dónde estás';

  @override
  String get sos_confirmed_body =>
      'El servidor confirmó tu alerta. El grupo ya puede ver tu ubicación.';

  @override
  String get sos_confirmed_chip => 'Alerta confirmada';

  @override
  String get sos_closed_title => 'Tu SOS está cerrado';

  @override
  String get sos_closed_body => 'El grupo ya no ve tu alerta activa.';

  @override
  String sos_coordinates_precision(int meters) {
    return 'Precisión ±$meters m';
  }

  @override
  String sos_call_contact_cta(String name) {
    return 'Llamar a mi contacto · $name';
  }

  @override
  String sos_call_organizer_cta(String name) {
    return 'Llamar al organizador · $name';
  }

  @override
  String get sos_no_contact_warning =>
      'No tienes un contacto de emergencia guardado. Usa el SMS o llama al organizador.';

  @override
  String get sos_sms_cta => 'Enviar SMS con mi ubicación';

  @override
  String sos_sms_body(String lat, String lng, String link) {
    return 'Necesito ayuda. Mi ubicación: $lat,$lng $link';
  }

  @override
  String get sos_call_123_cta => 'Llamar al 123';

  @override
  String get sos_close_cta => 'Ya estoy bien — cerrar SOS';

  @override
  String get sos_close_confirm_title => '¿Cerrar tu SOS?';

  @override
  String get sos_close_confirm_body =>
      'Ciérralo solo cuando estés bien de verdad.';

  @override
  String get sos_close_confirm_cta => 'Sí, estoy bien';

  @override
  String get sos_close_confirm_cancel => 'Cancelar';

  @override
  String sos_other_banner_title(String name, String distance) {
    return '$name pidió ayuda · $distance';
  }

  @override
  String get sos_other_banner_cta => 'Ver';

  @override
  String sos_other_asked_help_minutes(int minutes) {
    return 'Pidió ayuda · Hace $minutes min';
  }

  @override
  String sos_other_distance_from_me(String distance) {
    return '$distance de ti';
  }

  @override
  String sos_other_call_cta(String name) {
    return 'Llamar a $name';
  }

  @override
  String get sos_other_view_map_cta => 'Ver en el mapa';

  @override
  String get sos_other_resolve_cta => 'Marcar como resuelto · solo organizador';

  @override
  String get sos_other_resolve_note =>
      'Solo el organizador o quien pidió ayuda pueden cerrarlo.';

  @override
  String sos_other_close_confirm_title(String name) {
    return '¿Cerrar el SOS de $name?';
  }

  @override
  String sos_other_close_confirm_body(String name) {
    return 'Hazlo solo si confirmaste con $name que ya está bien.';
  }

  @override
  String get sos_other_close_confirm_cta => 'Sí, está bien';

  @override
  String get sos_other_close_confirm_cancel => 'Cancelar';

  @override
  String get live_ride_leader_distance_suffix => 'del líder';

  @override
  String get live_riders_page_header => 'Riders';

  @override
  String live_riders_page_subtitle(int count, int sharing) {
    return '$count riders · $sharing comparten ubicación';
  }

  @override
  String get live_ride_view_live_cta => 'Ver rodada en vivo';

  @override
  String get live_ride_own_sos_banner => 'Tienes un SOS activo en esta rodada';
}
