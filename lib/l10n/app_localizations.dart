import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// Botón para reintentar tras un error
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get common_retry;

  /// Título genérico de estado de error
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar esto'**
  String get common_error_title;

  /// Cuerpo genérico de estado de error
  ///
  /// In es, this message translates to:
  /// **'Algo falló de nuestro lado. Inténtalo de nuevo.'**
  String get common_error_body;

  /// Título genérico de estado vacío
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay nada aquí'**
  String get common_empty_title;

  /// Título del estado sin internet
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get common_offline_title;

  /// Cuerpo del estado sin internet
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo. Rideglory necesita internet para esto.'**
  String get common_offline_body;

  /// Título del estado sin permiso de ubicación
  ///
  /// In es, this message translates to:
  /// **'Necesitamos tu ubicación'**
  String get common_location_permission_title;

  /// Cuerpo del estado sin permiso de ubicación
  ///
  /// In es, this message translates to:
  /// **'Sin este permiso no podemos mostrarte esto. Actívalo desde los ajustes del sistema.'**
  String get common_location_permission_body;

  /// Acción para abrir ajustes de permiso de ubicación
  ///
  /// In es, this message translates to:
  /// **'Dar permiso'**
  String get common_location_permission_action;

  /// Título del estado sin GPS activo
  ///
  /// In es, this message translates to:
  /// **'Tu GPS está apagado'**
  String get common_no_gps_title;

  /// Cuerpo del estado sin GPS activo
  ///
  /// In es, this message translates to:
  /// **'Actívalo para que podamos ubicarte con precisión.'**
  String get common_no_gps_body;

  /// Acción para abrir ajustes de ubicación del sistema
  ///
  /// In es, this message translates to:
  /// **'Activar GPS'**
  String get common_no_gps_action;

  /// Etiqueta de la pestaña Mantenimiento en el Pill Tab Bar
  ///
  /// In es, this message translates to:
  /// **'MANTENIMIENTO'**
  String get maintenance_tab_label;

  /// Título del estado vacío de la pestaña Mantenimiento
  ///
  /// In es, this message translates to:
  /// **'Aún no registras mantenimientos'**
  String get maintenance_empty_title;

  /// Cuerpo del estado vacío de la pestaña Mantenimiento
  ///
  /// In es, this message translates to:
  /// **'Cuando registres el primero, aquí verás tu historial y lo que se viene.'**
  String get maintenance_empty_body;

  /// Etiqueta de la pestaña Eventos en el Pill Tab Bar
  ///
  /// In es, this message translates to:
  /// **'EVENTOS'**
  String get events_tab_label;

  /// Título del estado vacío de la pestaña Eventos
  ///
  /// In es, this message translates to:
  /// **'No hay rodadas por ahora'**
  String get events_empty_title;

  /// Cuerpo del estado vacío de la pestaña Eventos
  ///
  /// In es, this message translates to:
  /// **'Cuando alguien organice una rodada, aparecerá aquí.'**
  String get events_empty_body;

  /// Etiqueta de la pestaña Garaje en el Pill Tab Bar
  ///
  /// In es, this message translates to:
  /// **'GARAJE'**
  String get garage_tab_label;

  /// Título del estado vacío de la pestaña Garaje
  ///
  /// In es, this message translates to:
  /// **'Tu garaje está vacío'**
  String get garage_empty_title;

  /// Cuerpo del estado vacío de la pestaña Garaje
  ///
  /// In es, this message translates to:
  /// **'Agrega tu primera moto para llevar su mantenimiento y documentos.'**
  String get garage_empty_body;

  /// Etiqueta de la pestaña Perfil en el Pill Tab Bar
  ///
  /// In es, this message translates to:
  /// **'PERFIL'**
  String get profile_tab_label;

  /// Título del estado vacío de la pestaña Perfil
  ///
  /// In es, this message translates to:
  /// **'Tu perfil'**
  String get profile_empty_title;

  /// Cuerpo del estado vacío de la pestaña Perfil
  ///
  /// In es, this message translates to:
  /// **'Aquí vas a gestionar tus datos, tu contacto de emergencia y tu cuenta.'**
  String get profile_empty_body;

  /// Título de la pantalla de bienvenida
  ///
  /// In es, this message translates to:
  /// **'Rideglory'**
  String get welcome_title;

  /// Subtítulo de la pantalla de bienvenida
  ///
  /// In es, this message translates to:
  /// **'Tu garaje, tu mantenimiento y tus rodadas en un solo lugar.'**
  String get welcome_subtitle;

  /// Botón para continuar con correo en bienvenida (deshabilitado hasta F4)
  ///
  /// In es, this message translates to:
  /// **'Continuar con correo'**
  String get welcome_continue_email;

  /// Título de la galería del garaje
  ///
  /// In es, this message translates to:
  /// **'Mi garaje'**
  String get garage_title;

  /// Botón para agregar una moto (vacío/CTA largo)
  ///
  /// In es, this message translates to:
  /// **'Agregar moto'**
  String get garage_add_vehicle_button;

  /// Texto corto en la celda de agregar moto de la galería
  ///
  /// In es, this message translates to:
  /// **'Agregar moto'**
  String get garage_add_vehicle_button_short;

  /// Título del flujo de alta de moto
  ///
  /// In es, this message translates to:
  /// **'Agregar moto'**
  String get garage_add_vehicle_title;

  /// Título de la ficha de edición de moto
  ///
  /// In es, this message translates to:
  /// **'Editar moto'**
  String get garage_edit_vehicle_title;

  /// Título de error de la galería del garaje
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu garaje'**
  String get garage_error_title;

  /// Pregunta del paso 1 de alta de moto
  ///
  /// In es, this message translates to:
  /// **'¿Cuál es la placa?'**
  String get garage_plate_question;

  /// Subtítulo del paso de placa
  ///
  /// In es, this message translates to:
  /// **'Es lo único que necesitamos para empezar. Lo demás lo enseguidas.'**
  String get garage_plate_hint;

  /// Label del campo de placa
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get garage_plate_field_label;

  /// Texto de ayuda del campo de placa
  ///
  /// In es, this message translates to:
  /// **'Formato de moto: tres letras, dos números y una letra.'**
  String get garage_plate_helper;

  /// Error de formato de placa inválida
  ///
  /// In es, this message translates to:
  /// **'Esa placa no parece de moto. Van tres letras, dos números y una letra, por ejemplo ABC12D.'**
  String get garage_plate_invalid_error;

  /// Botón continuar del paso de placa
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get garage_continue_button;

  /// Enlace para volver a corregir la placa ya confirmada
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get garage_change_plate_button;

  /// Label del campo de marca
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get garage_brand_field_label;

  /// Label del campo de línea/modelo
  ///
  /// In es, this message translates to:
  /// **'Línea'**
  String get garage_model_field_label;

  /// Label del campo de año
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get garage_year_field_label;

  /// Label del campo de cilindraje
  ///
  /// In es, this message translates to:
  /// **'Cilindraje'**
  String get garage_engine_cc_field_label;

  /// Sufijo de unidad del campo de cilindraje
  ///
  /// In es, this message translates to:
  /// **'cc'**
  String get garage_engine_cc_suffix;

  /// Label del campo de kilometraje al crear la moto
  ///
  /// In es, this message translates to:
  /// **'Kilometraje de hoy'**
  String get garage_mileage_today_label;

  /// Label del campo de kilometraje al editar la moto
  ///
  /// In es, this message translates to:
  /// **'Kilometraje actual'**
  String get garage_mileage_current_label;

  /// Sufijo de unidad del campo de kilometraje
  ///
  /// In es, this message translates to:
  /// **'km'**
  String get garage_mileage_suffix;

  /// Ayuda del campo de kilometraje al crear
  ///
  /// In es, this message translates to:
  /// **'Desde acá arrancamos tu odómetro.'**
  String get garage_mileage_create_helper;

  /// Ayuda del campo de kilometraje al editar
  ///
  /// In es, this message translates to:
  /// **'Se actualiza solo cuando registras un mantenimiento.'**
  String get garage_mileage_edit_helper;

  /// Kilometraje formateado de una moto en la celda de galería
  ///
  /// In es, this message translates to:
  /// **'{km} km'**
  String garage_mileage_value(String km);

  /// Label de la fila de foto sin seleccionar
  ///
  /// In es, this message translates to:
  /// **'Agregar foto (opcional)'**
  String get garage_photo_add_label;

  /// Label de la fila de foto cuando ya hay una elegida
  ///
  /// In es, this message translates to:
  /// **'Foto lista'**
  String get garage_photo_selected_label;

  /// Ayuda de la fila de foto de la moto
  ///
  /// In es, this message translates to:
  /// **'Puedes agregarla o cambiarla después.'**
  String get garage_photo_add_hint;

  /// Botón para guardar una moto nueva
  ///
  /// In es, this message translates to:
  /// **'Guardar moto'**
  String get garage_save_vehicle_button;

  /// Botón para guardar cambios de una moto existente
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get garage_save_changes_button;

  /// Label del botón mientras se guarda la moto
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get garage_saving_label;

  /// Título del banner de error al guardar la moto
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar tu moto'**
  String get garage_save_error_title;

  /// Cuerpo del banner de error al guardar la moto
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo. Tus datos siguen aquí.'**
  String get garage_save_error_body;

  /// Label del switch de moto principal
  ///
  /// In es, this message translates to:
  /// **'Moto principal'**
  String get garage_main_vehicle_label;

  /// Botón para eliminar una moto
  ///
  /// In es, this message translates to:
  /// **'Eliminar moto'**
  String get garage_delete_vehicle_button;

  /// Título del diálogo de confirmación de borrado
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar esta moto?'**
  String get garage_delete_confirm_title;

  /// Cuerpo del diálogo de confirmación de borrado
  ///
  /// In es, this message translates to:
  /// **'Se borran también sus mantenimientos y documentos. No se puede deshacer.'**
  String get garage_delete_confirm_body;

  /// Botón cancelar del diálogo de borrado
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get garage_delete_cancel;

  /// Botón confirmar del diálogo de borrado
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get garage_delete_confirm_action;

  /// Botón para archivar una moto
  ///
  /// In es, this message translates to:
  /// **'Archivar moto'**
  String get garage_archive_vehicle_button;

  /// Botón para restaurar una moto archivada
  ///
  /// In es, this message translates to:
  /// **'Restaurar moto'**
  String get garage_unarchive_vehicle_button;

  /// Título de la sección de documentos en la ficha de la moto
  ///
  /// In es, this message translates to:
  /// **'DOCUMENTOS'**
  String get garage_documents_section_title;

  /// Abreviatura del SOAT en la alerta de la galería
  ///
  /// In es, this message translates to:
  /// **'SOAT'**
  String get garage_document_kind_soat;

  /// Abreviatura de la tecnomecánica en la alerta de la galería
  ///
  /// In es, this message translates to:
  /// **'Tecno'**
  String get garage_document_kind_rtm;

  /// Chip de alerta de documento vencido en la celda de galería
  ///
  /// In es, this message translates to:
  /// **'{kind} · vencido'**
  String garage_document_alert_expired(String kind);

  /// Chip de alerta de documento por vencer en la celda de galería
  ///
  /// In es, this message translates to:
  /// **'{kind} · {days, plural, one{1 día} other{{days} días}}'**
  String garage_document_alert_expiring(String kind, int days);

  /// Título del buscador de marca
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get garage_brand_picker_title;

  /// Label del buscador de marca
  ///
  /// In es, this message translates to:
  /// **'Buscar marca'**
  String get garage_brand_search_label;

  /// Título de sin resultados en el buscador de marca
  ///
  /// In es, this message translates to:
  /// **'No encontramos esa marca'**
  String get garage_brand_search_empty_title;

  /// Cuerpo de sin resultados en el buscador de marca
  ///
  /// In es, this message translates to:
  /// **'Prueba con otro nombre.'**
  String get garage_brand_search_empty;

  /// Título de las pantallas de SOAT
  ///
  /// In es, this message translates to:
  /// **'SOAT'**
  String get documents_soat_title;

  /// Título de las pantallas de tecnomecánica
  ///
  /// In es, this message translates to:
  /// **'Tecnomecánica'**
  String get documents_rtm_title;

  /// Título del estado sin subir de un documento
  ///
  /// In es, this message translates to:
  /// **'Todavía no has subido tu {kind}'**
  String documents_not_uploaded_title(String kind);

  /// Cuerpo del estado sin subir de un documento
  ///
  /// In es, this message translates to:
  /// **'Sácale una foto y en el teléfono la muestras aunque no tengas señal.'**
  String get documents_not_uploaded_body;

  /// Texto corto de estado sin subir en la fila de documentos
  ///
  /// In es, this message translates to:
  /// **'Sin subir'**
  String get documents_not_uploaded_short;

  /// Botón para subir un documento
  ///
  /// In es, this message translates to:
  /// **'Subir {kind}'**
  String documents_upload_button(String kind);

  /// Nota de privacidad del flujo de documentos
  ///
  /// In es, this message translates to:
  /// **'Queda privado: solo tú lo ves hasta que decidas compartirlo.'**
  String get documents_privacy_note;

  /// Título del banner de visor sin conexión
  ///
  /// In es, this message translates to:
  /// **'Estás sin conexión'**
  String get documents_offline_banner_title;

  /// Cuerpo del banner de visor sin conexión
  ///
  /// In es, this message translates to:
  /// **'Tu documento se abre igual: está guardado en el teléfono.'**
  String get documents_offline_banner_body;

  /// Nota persistente del visor de documentos
  ///
  /// In es, this message translates to:
  /// **'Guardado en tu teléfono: se abre sin señal.'**
  String get documents_saved_locally_note;

  /// Botón compartir del visor de documentos
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get documents_share_button;

  /// Botón reemplazar del visor de documentos
  ///
  /// In es, this message translates to:
  /// **'Reemplazar documento'**
  String get documents_replace_button;

  /// Fecha de vencimiento mostrada en la fila de documentos
  ///
  /// In es, this message translates to:
  /// **'Vence el {date}'**
  String documents_expires_on(String date);

  /// Chip de estado vigente de un documento
  ///
  /// In es, this message translates to:
  /// **'Vigente'**
  String get documents_status_valid;

  /// Chip de estado por vencer de un documento
  ///
  /// In es, this message translates to:
  /// **'Vence pronto'**
  String get documents_status_expiring_soon;

  /// Chip de estado vencido de un documento
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get documents_status_expired;

  /// Título del paso de origen de subida de documento
  ///
  /// In es, this message translates to:
  /// **'¿De dónde lo sacamos?'**
  String get documents_upload_origin_title;

  /// Subtítulo del paso de origen de subida de documento
  ///
  /// In es, this message translates to:
  /// **'Elige cómo quieres agregar el documento.'**
  String get documents_upload_origin_subtitle;

  /// Opción de origen: cámara
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get documents_origin_camera;

  /// Opción de origen: galería
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get documents_origin_gallery;

  /// Opción de origen: archivo PDF
  ///
  /// In es, this message translates to:
  /// **'Subir un PDF'**
  String get documents_origin_pdf;

  /// Pregunta del paso de confirmación de subida de documento
  ///
  /// In es, this message translates to:
  /// **'¿Se ve completo y legible?'**
  String get documents_confirm_question;

  /// Label del campo de número de póliza del SOAT
  ///
  /// In es, this message translates to:
  /// **'Número de póliza'**
  String get documents_policy_number_label;

  /// Label del campo de aseguradora del SOAT
  ///
  /// In es, this message translates to:
  /// **'Aseguradora'**
  String get documents_issuer_label;

  /// Ayuda cuando el OCR prellenó un campo del SOAT
  ///
  /// In es, this message translates to:
  /// **'Lo tomamos de la foto. Revisa que esté bien.'**
  String get documents_autofilled_hint;

  /// Label del campo de fecha de vencimiento
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo vence?'**
  String get documents_expiry_date_label;

  /// Ayuda del campo de fecha de vencimiento
  ///
  /// In es, this message translates to:
  /// **'Te avisamos en el teléfono cuando se acerque.'**
  String get documents_expiry_date_helper;

  /// Texto de la vista previa cuando el archivo es un PDF
  ///
  /// In es, this message translates to:
  /// **'Documento PDF'**
  String get documents_pdf_preview_label;

  /// Botón guardar del flujo de subida de documento
  ///
  /// In es, this message translates to:
  /// **'Guardar documento'**
  String get documents_save_button;

  /// Label del botón mientras se guarda el documento
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get documents_saving_label;

  /// Título del banner de error al guardar un documento
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar tu documento'**
  String get documents_save_error_title;

  /// Cuerpo del banner de error al guardar un documento
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get documents_save_error_body;

  /// Botón para repetir la captura en la subida de documento
  ///
  /// In es, this message translates to:
  /// **'Repetir la foto'**
  String get documents_retake_button;

  /// Cuerpo de la notificación local de recordatorio de vencimiento
  ///
  /// In es, this message translates to:
  /// **'{days, plural, one{Vence mañana} other{Vence en {days} días}}'**
  String documents_reminder_body(int days);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
