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
}
