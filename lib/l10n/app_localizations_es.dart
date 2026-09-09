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
