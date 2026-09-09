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
  /// **'Registra tu primer mantenimiento'**
  String get maintenance_empty_title;

  /// Cuerpo del estado vacío de la pestaña Mantenimiento
  ///
  /// In es, this message translates to:
  /// **'Lleva el kilometraje, los cambios de aceite y los recordatorios de tus motos en un solo lugar.'**
  String get maintenance_empty_body;

  /// Botón del estado vacío de mantenimiento
  ///
  /// In es, this message translates to:
  /// **'Registrar mantenimiento'**
  String get maintenance_empty_action;

  /// Título del encabezado de la pantalla principal de mantenimiento
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get maintenance_page_title;

  /// Semántica del botón de filtro en el encabezado de mantenimiento
  ///
  /// In es, this message translates to:
  /// **'Filtrar por estado'**
  String get maintenance_filter_action_label;

  /// Chip para ver todas las motos en mantenimiento
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get maintenance_filter_all;

  /// Título de la sección de próximos servicios
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMOS'**
  String get maintenance_section_agenda;

  /// Título de la sección de historial de mantenimiento
  ///
  /// In es, this message translates to:
  /// **'HISTORIAL'**
  String get maintenance_section_history;

  /// Título de la sección de recordatorio en detalle y registro
  ///
  /// In es, this message translates to:
  /// **'RECORDATORIO'**
  String get maintenance_section_reminder;

  /// Etiqueta de urgencia: el servicio ya se pasó
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get maintenance_urgency_overdue;

  /// Etiqueta de urgencia: el servicio vence este mes
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get maintenance_urgency_due_soon;

  /// Etiqueta de urgencia: el servicio todavía no se acerca
  ///
  /// In es, this message translates to:
  /// **'Más adelante'**
  String get maintenance_urgency_upcoming;

  /// Valor en kilómetros
  ///
  /// In es, this message translates to:
  /// **'{value} km'**
  String maintenance_value_km(String value);

  /// Valor en días
  ///
  /// In es, this message translates to:
  /// **'{value} días'**
  String maintenance_value_days(String value);

  /// Semántica del FAB de registrar mantenimiento
  ///
  /// In es, this message translates to:
  /// **'Registrar mantenimiento'**
  String get maintenance_fab_label;

  /// Título de la hoja de filtro por estado
  ///
  /// In es, this message translates to:
  /// **'Filtrar por estado'**
  String get maintenance_filter_sheet_title;

  /// Opción de filtro: todos los estados
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get maintenance_filter_status_all;

  /// Opción de filtro: solo vencidos
  ///
  /// In es, this message translates to:
  /// **'Vencidos'**
  String get maintenance_filter_status_overdue;

  /// Opción de filtro: solo los de este mes
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get maintenance_filter_status_due_soon;

  /// Opción de filtro: solo los que no son urgentes
  ///
  /// In es, this message translates to:
  /// **'Al día'**
  String get maintenance_filter_status_upcoming;

  /// Título del estado de error de la pantalla principal de mantenimiento
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu mantenimiento'**
  String get maintenance_error_title;

  /// Cuerpo del estado sin conexión de la pantalla principal de mantenimiento
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu mantenimiento. Revisa tu conexión e inténtalo de nuevo.'**
  String get maintenance_offline_body;

  /// Etiqueta corta del campo taller en el detalle
  ///
  /// In es, this message translates to:
  /// **'Taller'**
  String get maintenance_detail_field_workshop;

  /// Etiqueta corta del campo costo en el detalle
  ///
  /// In es, this message translates to:
  /// **'Costo'**
  String get maintenance_detail_field_cost;

  /// Etiqueta corta del campo nota en el detalle
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get maintenance_detail_field_note;

  /// Recordatorio por kilometraje en el detalle
  ///
  /// In es, this message translates to:
  /// **'Próximo a los {value} km'**
  String maintenance_detail_reminder_next_km(String value);

  /// Recordatorio por fecha en el detalle
  ///
  /// In es, this message translates to:
  /// **'O el {date} · toca para cambiar'**
  String maintenance_detail_reminder_next_date(String date);

  /// Título de la sección de registros anteriores
  ///
  /// In es, this message translates to:
  /// **'ANTES, EN ESTA MOTO'**
  String get maintenance_detail_previous_section;

  /// Cuánto duró un registro anterior
  ///
  /// In es, this message translates to:
  /// **'Duró {value} km'**
  String maintenance_detail_duration(String value);

  /// Expandir la lista de anteriores
  ///
  /// In es, this message translates to:
  /// **'Ver {count} más'**
  String maintenance_detail_see_more(int count);

  /// Contraer la lista de anteriores
  ///
  /// In es, this message translates to:
  /// **'Ver menos'**
  String get maintenance_detail_see_less;

  /// Promedio de duración entre servicios
  ///
  /// In es, this message translates to:
  /// **'Te dura {value} km en promedio.'**
  String maintenance_detail_average(String value);

  /// Semántica del botón de tres puntos en el detalle
  ///
  /// In es, this message translates to:
  /// **'Más acciones'**
  String get maintenance_detail_menu_semantic;

  /// Acción de editar en la hoja de acciones del detalle
  ///
  /// In es, this message translates to:
  /// **'Editar registro'**
  String get maintenance_actions_sheet_edit;

  /// Acción de eliminar en la hoja de acciones del detalle
  ///
  /// In es, this message translates to:
  /// **'Eliminar registro'**
  String get maintenance_actions_sheet_delete;

  /// Título de la confirmación de borrado
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este registro?'**
  String get maintenance_delete_confirm_title;

  /// Cuerpo de la confirmación de borrado
  ///
  /// In es, this message translates to:
  /// **'Se borra {type} del {date}, y con él el recordatorio del próximo cambio. No se puede deshacer.'**
  String maintenance_delete_confirm_body(String type, String date);

  /// Botón de confirmar borrado
  ///
  /// In es, this message translates to:
  /// **'Sí, eliminar'**
  String get maintenance_delete_confirm_action;

  /// Botón de cancelar el borrado
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get maintenance_delete_confirm_cancel;

  /// Título del encabezado del asistente de registro
  ///
  /// In es, this message translates to:
  /// **'Registrar mantenimiento'**
  String get maintenance_register_title;

  /// Título del encabezado del asistente al editar
  ///
  /// In es, this message translates to:
  /// **'Editar mantenimiento'**
  String get maintenance_edit_title;

  /// Indicador de paso del asistente
  ///
  /// In es, this message translates to:
  /// **'Paso {step} de 3'**
  String maintenance_register_step_label(int step);

  /// Pregunta del paso 1 del asistente
  ///
  /// In es, this message translates to:
  /// **'¿Qué mantenimiento registras?'**
  String get maintenance_register_step1_question;

  /// Pregunta del paso 1 cuando el tipo es texto libre
  ///
  /// In es, this message translates to:
  /// **'¿Qué mantenimiento fue?'**
  String get maintenance_register_step1_other_question;

  /// Sugerencia de tipo de mantenimiento: aceite
  ///
  /// In es, this message translates to:
  /// **'Cambio de aceite y filtro'**
  String get maintenance_type_oil_change;

  /// Sugerencia de tipo de mantenimiento: llanta
  ///
  /// In es, this message translates to:
  /// **'Cambio de llanta'**
  String get maintenance_type_tire_change;

  /// Sugerencia de tipo de mantenimiento: frenos
  ///
  /// In es, this message translates to:
  /// **'Pastillas de freno'**
  String get maintenance_type_brake_pads;

  /// Sugerencia de tipo de mantenimiento: kit de arrastre
  ///
  /// In es, this message translates to:
  /// **'Kit de arrastre'**
  String get maintenance_type_drive_kit;

  /// Sugerencia de tipo de mantenimiento: revisión general
  ///
  /// In es, this message translates to:
  /// **'Revisión general'**
  String get maintenance_type_general_check;

  /// Sugerencia de tipo de mantenimiento: texto libre
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get maintenance_type_other;

  /// Label del campo de texto libre del tipo de mantenimiento
  ///
  /// In es, this message translates to:
  /// **'Tipo de mantenimiento'**
  String get maintenance_type_other_field_label;

  /// Ayuda del campo de texto libre del tipo de mantenimiento
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre del mantenimiento, por ejemplo: \"Cambio de bujías\".'**
  String get maintenance_type_other_field_hint;

  /// Pregunta del paso 2 del asistente
  ///
  /// In es, this message translates to:
  /// **'¿Cuál es el kilometraje?'**
  String get maintenance_register_step2_question;

  /// Sufijo del campo de kilometraje
  ///
  /// In es, this message translates to:
  /// **'km'**
  String get maintenance_register_odometer_suffix;

  /// Ayuda cuando el kilometraje ingresado actualiza el odómetro
  ///
  /// In es, this message translates to:
  /// **'Ahora tiene {current} km. Con esto tu odómetro quedaría actualizado a {value} km.'**
  String maintenance_register_odometer_helper_will_update(
    String current,
    String value,
  );

  /// Ayuda cuando el kilometraje ingresado es menor al odómetro actual
  ///
  /// In es, this message translates to:
  /// **'Es un registro anterior: tu moto ya va en {current} km y el odómetro no cambia.'**
  String maintenance_register_odometer_helper_past_record(String current);

  /// Pregunta del paso 3 del asistente
  ///
  /// In es, this message translates to:
  /// **'¿Algún detalle más?'**
  String get maintenance_register_step3_question;

  /// Subtítulo del paso 3 del asistente
  ///
  /// In es, this message translates to:
  /// **'Todo esto es opcional. Puedes guardar así.'**
  String get maintenance_register_step3_subtitle;

  /// Label del campo fecha
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get maintenance_field_date;

  /// Label del campo taller en el registro
  ///
  /// In es, this message translates to:
  /// **'Taller o quién lo hizo'**
  String get maintenance_field_workshop;

  /// Label del campo costo
  ///
  /// In es, this message translates to:
  /// **'Costo'**
  String get maintenance_field_cost;

  /// Label del campo nota
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get maintenance_field_note;

  /// Label del switch de recordatorio
  ///
  /// In es, this message translates to:
  /// **'Avisarme del próximo'**
  String get maintenance_reminder_toggle_label;

  /// Subtítulo del switch de recordatorio apagado
  ///
  /// In es, this message translates to:
  /// **'Opcional. Está apagado.'**
  String get maintenance_reminder_toggle_off;

  /// Subtítulo del switch de recordatorio encendido
  ///
  /// In es, this message translates to:
  /// **'{summary} · toca para cambiar'**
  String maintenance_reminder_toggle_on(String summary);

  /// Resumen de intervalo solo en kilómetros
  ///
  /// In es, this message translates to:
  /// **'Cada {km} km'**
  String maintenance_reminder_km_only(String km);

  /// Resumen de intervalo solo en meses
  ///
  /// In es, this message translates to:
  /// **'Cada {months} meses'**
  String maintenance_reminder_months_only(String months);

  /// Resumen de intervalo en kilómetros y meses
  ///
  /// In es, this message translates to:
  /// **'Cada {km} km o {months} meses'**
  String maintenance_reminder_both(String km, String months);

  /// Título de la hoja de intervalo del recordatorio
  ///
  /// In es, this message translates to:
  /// **'¿Cada cuánto te aviso?'**
  String get maintenance_interval_sheet_title;

  /// Subtítulo de la hoja de intervalo
  ///
  /// In es, this message translates to:
  /// **'{type} · {vehicle}'**
  String maintenance_interval_sheet_subtitle(String type, String vehicle);

  /// Label del campo de intervalo en kilómetros
  ///
  /// In es, this message translates to:
  /// **'Avísame cada'**
  String get maintenance_interval_km_label;

  /// Sufijo del campo de intervalo en kilómetros
  ///
  /// In es, this message translates to:
  /// **'km'**
  String get maintenance_interval_km_suffix;

  /// Label del campo de intervalo en meses
  ///
  /// In es, this message translates to:
  /// **'O cada'**
  String get maintenance_interval_months_label;

  /// Sufijo del campo de intervalo en meses
  ///
  /// In es, this message translates to:
  /// **'meses'**
  String get maintenance_interval_months_suffix;

  /// Ayuda de la hoja de intervalo
  ///
  /// In es, this message translates to:
  /// **'Con uno basta. Si pones los dos, te avisamos con el que se cumpla primero.'**
  String get maintenance_interval_helper;

  /// Botón de avanzar de paso
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get maintenance_action_next;

  /// Botón de guardar el mantenimiento
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get maintenance_action_save;

  /// Estado de guardando del botón
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get maintenance_action_saving;

  /// Título del banner de error al guardar
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar'**
  String get maintenance_save_error_title;

  /// Cuerpo del banner de error al guardar
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo. Tus datos siguen aquí.'**
  String get maintenance_save_error_body;

  /// Título del aviso propio antes del permiso de notificaciones del sistema
  ///
  /// In es, this message translates to:
  /// **'Activa los avisos de mantenimiento'**
  String get maintenance_notification_permission_title;

  /// Cuerpo del aviso propio antes del permiso de notificaciones del sistema
  ///
  /// In es, this message translates to:
  /// **'Te avisamos en el celular cuando se acerque el próximo servicio. Puedes desactivarlo cuando quieras.'**
  String get maintenance_notification_permission_body;

  /// Botón de aceptar el aviso propio de notificaciones
  ///
  /// In es, this message translates to:
  /// **'Activar avisos'**
  String get maintenance_notification_permission_action;

  /// Botón de descartar el aviso propio de notificaciones
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get maintenance_notification_permission_dismiss;

  /// Título de la notificación local del próximo servicio
  ///
  /// In es, this message translates to:
  /// **'Se acerca un mantenimiento'**
  String get maintenance_notification_title;

  /// Cuerpo de la notificación local del próximo servicio
  ///
  /// In es, this message translates to:
  /// **'{type} de tu {vehicle}.'**
  String maintenance_notification_body(String type, String vehicle);

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
