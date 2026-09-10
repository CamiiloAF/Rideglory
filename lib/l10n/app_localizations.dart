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

  /// Título del estado vacío cuando el rider no tiene motos en el garaje
  ///
  /// In es, this message translates to:
  /// **'Primero registra una moto'**
  String get maintenance_no_vehicles_title;

  /// Cuerpo del estado vacío cuando el rider no tiene motos en el garaje
  ///
  /// In es, this message translates to:
  /// **'El mantenimiento se lleva por moto: agrega la tuya al garaje para empezar a registrar.'**
  String get maintenance_no_vehicles_body;

  /// Botón del estado vacío cuando el rider no tiene motos en el garaje
  ///
  /// In es, this message translates to:
  /// **'Agregar moto'**
  String get maintenance_no_vehicles_action;

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

  /// Título del banner de error al borrar un mantenimiento
  ///
  /// In es, this message translates to:
  /// **'No pudimos eliminar el mantenimiento'**
  String get maintenance_delete_error_title;

  /// Cuerpo del banner de error al borrar un mantenimiento
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get maintenance_delete_error_body;

  /// Título del banner de error al editar el recordatorio de un mantenimiento
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el recordatorio'**
  String get maintenance_reminder_update_error_title;

  /// Cuerpo del banner de error al editar el recordatorio de un mantenimiento
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo.'**
  String get maintenance_reminder_update_error_body;

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

  /// Título del banner informativo cuando se guarda el mantenimiento sin recordatorio por no dar el permiso de notificaciones
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento guardado sin recordatorio'**
  String get maintenance_reminder_declined_title;

  /// Cuerpo del banner informativo cuando se guarda el mantenimiento sin recordatorio por no dar el permiso de notificaciones
  ///
  /// In es, this message translates to:
  /// **'Sin el permiso de notificaciones no podemos avisarte del próximo servicio. Puedes activarlo cuando quieras desde el mantenimiento.'**
  String get maintenance_reminder_declined_body;

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

  /// Label del switch de recordatorio en el visor de documentos
  ///
  /// In es, this message translates to:
  /// **'Recordarme el vencimiento'**
  String get documents_reminder_toggle_label;

  /// Subtítulo del switch de recordatorio en el visor de documentos
  ///
  /// In es, this message translates to:
  /// **'Te avisamos 30, 7 y 1 día antes.'**
  String get documents_reminder_toggle_subtitle;

  /// Título de la hoja de aviso propio antes del permiso de notificaciones
  ///
  /// In es, this message translates to:
  /// **'Antes de pedirte el permiso'**
  String get notification_permission_sheet_title;

  /// Cuerpo de la hoja de aviso propio antes del permiso de notificaciones
  ///
  /// In es, this message translates to:
  /// **'Rideglory te avisa de vencimientos de documentos y mantenimientos con notificaciones en el teléfono. Ahora te va a aparecer el permiso del sistema — dale \"Permitir\" para no perderte esos avisos.'**
  String get notification_permission_sheet_body;

  /// Botón para continuar al permiso del sistema desde la hoja de aviso propio
  ///
  /// In es, this message translates to:
  /// **'Permitir'**
  String get notification_permission_sheet_allow;

  /// Botón para cerrar la hoja de aviso propio de notificaciones sin pedir el permiso
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get notification_permission_sheet_cancel;

  /// Título de marca en bienvenida
  ///
  /// In es, this message translates to:
  /// **'Rideglory'**
  String get auth_welcome_title;

  /// Titular de la pantalla de bienvenida
  ///
  /// In es, this message translates to:
  /// **'Lleva la cuenta de tu moto sin acordarte de nada'**
  String get auth_welcome_headline;

  /// Título del primer punto de bienvenida
  ///
  /// In es, this message translates to:
  /// **'Cuánto te duró cada pieza'**
  String get auth_welcome_feature_maintenance_title;

  /// Cuerpo del primer punto de bienvenida
  ///
  /// In es, this message translates to:
  /// **'Registras el cambio con el kilometraje y la app te dice cuánto duró la anterior.'**
  String get auth_welcome_feature_maintenance_body;

  /// Título del segundo punto de bienvenida
  ///
  /// In es, this message translates to:
  /// **'Tus motos en un solo lugar'**
  String get auth_welcome_feature_garage_title;

  /// Cuerpo del segundo punto de bienvenida
  ///
  /// In es, this message translates to:
  /// **'Kilometraje, mantenimientos y documentos de cada moto.'**
  String get auth_welcome_feature_garage_body;

  /// Título del tercer punto de bienvenida
  ///
  /// In es, this message translates to:
  /// **'El SOAT abre sin señal'**
  String get auth_welcome_feature_documents_title;

  /// Cuerpo del tercer punto de bienvenida
  ///
  /// In es, this message translates to:
  /// **'Queda guardado en el teléfono para mostrarlo en un retén.'**
  String get auth_welcome_feature_documents_body;

  /// Botón de acceso con Google
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get auth_welcome_continue_google;

  /// Botón de acceso con Apple
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get auth_welcome_continue_apple;

  /// Botón de acceso con correo
  ///
  /// In es, this message translates to:
  /// **'Continuar con correo'**
  String get auth_welcome_continue_email;

  /// Aviso legal de bienvenida
  ///
  /// In es, this message translates to:
  /// **'Al continuar aceptas los Términos y la Política de privacidad.'**
  String get auth_welcome_legal;

  /// Título del header de login por correo
  ///
  /// In es, this message translates to:
  /// **'Entrar con correo'**
  String get auth_email_login_title;

  /// Label del campo correo
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get auth_email_field_label;

  /// Label del campo contraseña
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get auth_password_field_label;

  /// Acción para mostrar la contraseña
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get auth_password_show_action;

  /// Acción para ocultar la contraseña
  ///
  /// In es, this message translates to:
  /// **'Ocultar'**
  String get auth_password_hide_action;

  /// Enlace a recuperar contraseña
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get auth_forgot_password_link;

  /// Botón de inicio de sesión
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get auth_sign_in_button;

  /// Enlace para ir a registro
  ///
  /// In es, this message translates to:
  /// **'Crear una cuenta nueva'**
  String get auth_create_account_link;

  /// Enlace para volver a login desde registro
  ///
  /// In es, this message translates to:
  /// **'Ya tengo una cuenta'**
  String get auth_have_account_link;

  /// Título del banner de error de login
  ///
  /// In es, this message translates to:
  /// **'No pudimos iniciar sesión'**
  String get auth_error_banner_title;

  /// Texto de error bajo el campo contraseña
  ///
  /// In es, this message translates to:
  /// **'Revisa tu contraseña.'**
  String get auth_password_error_helper;

  /// Título del header de registro
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get auth_register_title;

  /// Label del campo nombre en registro
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get auth_register_name_label;

  /// Botón de registro
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get auth_register_button;

  /// Título del header de recuperar contraseña
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get auth_forgot_title;

  /// Titular de recuperar contraseña
  ///
  /// In es, this message translates to:
  /// **'Te mandamos un enlace'**
  String get auth_forgot_heading;

  /// Cuerpo de recuperar contraseña
  ///
  /// In es, this message translates to:
  /// **'Escribe el correo con el que te registraste y te enviamos un enlace para poner una contraseña nueva.'**
  String get auth_forgot_body;

  /// Botón de enviar enlace de recuperación
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get auth_forgot_send_button;

  /// Confirmación de envío de enlace de recuperación
  ///
  /// In es, this message translates to:
  /// **'Enlace enviado'**
  String get auth_forgot_sent_title;

  /// Cuerpo de confirmación de envío de enlace
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo, incluida la carpeta de spam.'**
  String get auth_forgot_sent_body;

  /// Validación de campo vacío
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio.'**
  String get auth_field_required;

  /// Validación de correo inválido
  ///
  /// In es, this message translates to:
  /// **'Escribe un correo válido.'**
  String get auth_email_invalid;

  /// Validación de contraseña corta
  ///
  /// In es, this message translates to:
  /// **'Usa una contraseña de al menos 6 caracteres.'**
  String get auth_password_too_short;

  /// Error: credenciales inválidas
  ///
  /// In es, this message translates to:
  /// **'El correo o la contraseña no coinciden. Revísalos e inténtalo otra vez.'**
  String get auth_error_invalid_credentials;

  /// Error: correo ya registrado
  ///
  /// In es, this message translates to:
  /// **'Ese correo ya tiene una cuenta. Intenta iniciar sesión.'**
  String get auth_error_email_already_registered;

  /// Error: contraseña débil
  ///
  /// In es, this message translates to:
  /// **'Usa una contraseña de al menos 6 caracteres.'**
  String get auth_error_weak_password;

  /// Error: usuario no encontrado
  ///
  /// In es, this message translates to:
  /// **'No encontramos una cuenta con ese correo.'**
  String get auth_error_user_not_found;

  /// Error: proveedor cancelado
  ///
  /// In es, this message translates to:
  /// **'Cancelaste el inicio de sesión.'**
  String get auth_error_provider_cancelled;

  /// Error: sin conexión
  ///
  /// In es, this message translates to:
  /// **'No hay conexión. Revisa tu internet e inténtalo de nuevo.'**
  String get auth_error_offline;

  /// Error: desconocido
  ///
  /// In es, this message translates to:
  /// **'Algo falló. Inténtalo de nuevo.'**
  String get auth_error_unknown;

  /// Título del header de Perfil
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profile_title;

  /// Etiqueta accesible del ícono de ajustes en la ficha del rider
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get profile_settings_icon_label;

  /// Encabezado de sección Cuenta
  ///
  /// In es, this message translates to:
  /// **'CUENTA'**
  String get profile_section_account;

  /// Fila de ajuste: nombre
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get profile_field_name;

  /// Fila de ajuste: correo
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get profile_field_email;

  /// Encabezado de sección de emergencia
  ///
  /// In es, this message translates to:
  /// **'EN CASO DE EMERGENCIA'**
  String get profile_section_emergency;

  /// Fila de ajuste: contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'Contacto de emergencia'**
  String get profile_emergency_contact_label;

  /// Valor cuando no hay contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'Sin configurar'**
  String get profile_emergency_not_configured;

  /// Acción para agregar contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get profile_emergency_add_action;

  /// Encabezado de sección de notificaciones y datos
  ///
  /// In es, this message translates to:
  /// **'NOTIFICACIONES Y DATOS'**
  String get profile_section_notifications;

  /// Switch de notificaciones
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get profile_notifications_label;

  /// Switch de analítica
  ///
  /// In es, this message translates to:
  /// **'Compartir datos de uso'**
  String get profile_share_usage_label;

  /// Subtítulo del switch de analítica
  ///
  /// In es, this message translates to:
  /// **'Nos ayuda a mejorar la app'**
  String get profile_share_usage_subtitle;

  /// Encabezado de sección legal
  ///
  /// In es, this message translates to:
  /// **'LEGAL'**
  String get profile_section_legal;

  /// Fila de ajuste: términos
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get profile_terms;

  /// Fila de ajuste: privacidad
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get profile_privacy;

  /// Fila de ajuste: consentimientos
  ///
  /// In es, this message translates to:
  /// **'Mis consentimientos'**
  String get profile_my_consents;

  /// Fila de ajuste: cerrar sesión
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profile_sign_out;

  /// Fila de ajuste: borrar cuenta
  ///
  /// In es, this message translates to:
  /// **'Borrar mi cuenta'**
  String get profile_delete_account;

  /// Título del banner de emergencia en la ficha del rider
  ///
  /// In es, this message translates to:
  /// **'En caso de emergencia'**
  String get profile_emergency_banner_title;

  /// Cuerpo del banner de emergencia
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes contacto de emergencia. Es el número al que llamarían tus compañeros si algo pasa en una rodada.'**
  String get profile_emergency_banner_body;

  /// Botón del banner de emergencia
  ///
  /// In es, this message translates to:
  /// **'Agregar contacto'**
  String get profile_emergency_add_contact_cta;

  /// Encabezado de la sección de motos en la ficha del rider
  ///
  /// In es, this message translates to:
  /// **'MIS MOTOS'**
  String get profile_my_vehicles_title;

  /// Encabezado del grupo de ajustes en la ficha del rider
  ///
  /// In es, this message translates to:
  /// **'AJUSTES'**
  String get profile_settings_group_title;

  /// Fila de ajuste combinada en la ficha del rider
  ///
  /// In es, this message translates to:
  /// **'Privacidad y consentimientos'**
  String get profile_privacy_and_consents;

  /// Título de error al cargar el perfil
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu perfil'**
  String get profile_load_error_title;

  /// Cuerpo de error al cargar el perfil
  ///
  /// In es, this message translates to:
  /// **'Algo falló de nuestro lado. Inténtalo de nuevo.'**
  String get profile_load_error_body;

  /// Título de estado sin conexión en perfil
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get profile_offline_title;

  /// Cuerpo de estado sin conexión en perfil
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar el perfil. Revisa tu conexión e inténtalo de nuevo.'**
  String get profile_offline_body;

  /// Título de la pantalla de edición de perfil
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profile_edit_title;

  /// Campo teléfono en editar perfil
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get profile_field_phone;

  /// Campo fecha de nacimiento en editar perfil
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get profile_field_birth_date;

  /// Campo ciudad en editar perfil
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get profile_field_city;

  /// Campo EPS en editar perfil
  ///
  /// In es, this message translates to:
  /// **'EPS'**
  String get profile_field_eps;

  /// Campo seguro médico en editar perfil
  ///
  /// In es, this message translates to:
  /// **'Seguro médico'**
  String get profile_field_insurance;

  /// Campo tipo de sangre en editar perfil
  ///
  /// In es, this message translates to:
  /// **'Tipo de sangre'**
  String get profile_field_blood_type;

  /// Placeholder del selector de tipo de sangre
  ///
  /// In es, this message translates to:
  /// **'Selecciona'**
  String get profile_blood_type_placeholder;

  /// Tipo de sangre O positivo
  ///
  /// In es, this message translates to:
  /// **'O+'**
  String get profile_blood_type_o_positive;

  /// Tipo de sangre O negativo
  ///
  /// In es, this message translates to:
  /// **'O-'**
  String get profile_blood_type_o_negative;

  /// Tipo de sangre A positivo
  ///
  /// In es, this message translates to:
  /// **'A+'**
  String get profile_blood_type_a_positive;

  /// Tipo de sangre A negativo
  ///
  /// In es, this message translates to:
  /// **'A-'**
  String get profile_blood_type_a_negative;

  /// Tipo de sangre B positivo
  ///
  /// In es, this message translates to:
  /// **'B+'**
  String get profile_blood_type_b_positive;

  /// Tipo de sangre B negativo
  ///
  /// In es, this message translates to:
  /// **'B-'**
  String get profile_blood_type_b_negative;

  /// Tipo de sangre AB positivo
  ///
  /// In es, this message translates to:
  /// **'AB+'**
  String get profile_blood_type_ab_positive;

  /// Tipo de sangre AB negativo
  ///
  /// In es, this message translates to:
  /// **'AB-'**
  String get profile_blood_type_ab_negative;

  /// Botón de guardar en editar perfil
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get profile_save_button;

  /// Confirmación de guardado de perfil
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado.'**
  String get profile_update_success;

  /// Error al guardar perfil
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar los cambios. Inténtalo de nuevo.'**
  String get profile_update_error;

  /// Título del header de contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'Contacto de emergencia'**
  String get profile_emergency_page_title;

  /// Título del aviso de contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'Para qué sirve'**
  String get profile_emergency_info_title;

  /// Cuerpo del aviso de contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'Es el número que verían tus compañeros de rodada si algo te pasa. Se guarda en tu teléfono para tenerlo a mano.'**
  String get profile_emergency_info_body;

  /// Campo nombre del contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get profile_emergency_field_name;

  /// Campo teléfono del contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get profile_emergency_field_phone;

  /// Campo parentesco del contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'Parentesco'**
  String get profile_emergency_field_relationship;

  /// Nota de consentimiento del contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'Avísale a esta persona que la registraste. Puedes cambiarla o borrarla cuando quieras.'**
  String get profile_emergency_consent_note;

  /// Botón de guardar contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'Guardar contacto'**
  String get profile_emergency_save_button;

  /// Confirmación de guardado de contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'Contacto de emergencia guardado.'**
  String get profile_emergency_save_success;

  /// Error al guardar contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el contacto. Inténtalo de nuevo.'**
  String get profile_emergency_save_error;

  /// Título de la pantalla de consentimientos
  ///
  /// In es, this message translates to:
  /// **'Mis consentimientos'**
  String get profile_consents_title;

  /// Título del estado vacío de consentimientos
  ///
  /// In es, this message translates to:
  /// **'Sin consentimientos registrados'**
  String get profile_consents_empty_title;

  /// Cuerpo del estado vacío de consentimientos
  ///
  /// In es, this message translates to:
  /// **'Aquí vas a ver cada consentimiento que aceptaste, con fecha y versión.'**
  String get profile_consents_empty_body;

  /// Tipo de consentimiento: aceptación de riesgo
  ///
  /// In es, this message translates to:
  /// **'Aceptación de riesgo'**
  String get profile_consent_kind_risk_acceptance;

  /// Tipo de consentimiento: médico
  ///
  /// In es, this message translates to:
  /// **'Consentimiento médico'**
  String get profile_consent_kind_medical_consent;

  /// Tipo de consentimiento: términos
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get profile_consent_kind_terms;

  /// Versión del consentimiento
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String profile_consent_version_label(String version);

  /// Título del header de borrar cuenta
  ///
  /// In es, this message translates to:
  /// **'Borrar mi cuenta'**
  String get profile_delete_step1_title;

  /// Titular de la explicación de borrar cuenta
  ///
  /// In es, this message translates to:
  /// **'Esto borra tu cuenta y todo lo que has guardado'**
  String get profile_delete_headline;

  /// Subtexto de la explicación de borrar cuenta
  ///
  /// In es, this message translates to:
  /// **'No es cerrar sesión: los datos se eliminan y no se pueden recuperar.'**
  String get profile_delete_subtext;

  /// Ítem: motos que se borran
  ///
  /// In es, this message translates to:
  /// **'{count} motos de tu garaje'**
  String profile_delete_item_vehicles(int count);

  /// Ítem: mantenimientos que se borran
  ///
  /// In es, this message translates to:
  /// **'{count} mantenimientos registrados'**
  String profile_delete_item_maintenances(int count);

  /// Ítem: documentos que se borran
  ///
  /// In es, this message translates to:
  /// **'{count} documentos guardados (SOAT y tecnomecánica)'**
  String profile_delete_item_documents(int count);

  /// Ítem: inscripciones que se borran
  ///
  /// In es, this message translates to:
  /// **'Tus inscripciones a rodadas'**
  String get profile_delete_item_registrations;

  /// Ítem: perfil que se borra
  ///
  /// In es, this message translates to:
  /// **'Tu perfil y tu contacto de emergencia'**
  String get profile_delete_item_profile;

  /// Aviso de cerrar sesión en vez de borrar cuenta
  ///
  /// In es, this message translates to:
  /// **'¿Solo quieres salir de la app?'**
  String get profile_delete_just_logout_title;

  /// Cuerpo del aviso de cerrar sesión
  ///
  /// In es, this message translates to:
  /// **'Cierra sesión desde el perfil: tus datos se quedan como están.'**
  String get profile_delete_just_logout_body;

  /// Botón para continuar con el borrado
  ///
  /// In es, this message translates to:
  /// **'Continuar con el borrado'**
  String get profile_delete_continue_button;

  /// Botón para cancelar el borrado desde la explicación
  ///
  /// In es, this message translates to:
  /// **'Mejor no, cancelar'**
  String get profile_delete_cancel_button;

  /// Título del sheet de confirmación de borrado
  ///
  /// In es, this message translates to:
  /// **'¿Borramos tu cuenta?'**
  String get profile_delete_confirm_title;

  /// Cuerpo del sheet de confirmación de borrado
  ///
  /// In es, this message translates to:
  /// **'Se eliminan tus {vehicles} motos, {maintenances} mantenimientos y {documents} documentos. Esta acción no se puede deshacer.'**
  String profile_delete_confirm_body(
    int vehicles,
    int maintenances,
    int documents,
  );

  /// Casilla de confirmación de borrado
  ///
  /// In es, this message translates to:
  /// **'Entiendo que no se puede recuperar'**
  String get profile_delete_confirm_checkbox;

  /// Botón final de confirmación de borrado
  ///
  /// In es, this message translates to:
  /// **'Sí, borrar mi cuenta'**
  String get profile_delete_confirm_button;

  /// Botón de cancelar en el sheet de confirmación
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get profile_delete_confirm_cancel;

  /// Título de la pantalla de progreso de borrado
  ///
  /// In es, this message translates to:
  /// **'Borrando tu cuenta...'**
  String get profile_delete_progress_title;

  /// Cuerpo de la pantalla de progreso de borrado
  ///
  /// In es, this message translates to:
  /// **'No cierres la app. Esto toma unos segundos.'**
  String get profile_delete_progress_body;

  /// Título del bloqueo por rodada activa
  ///
  /// In es, this message translates to:
  /// **'Todavía no puedes borrar la cuenta'**
  String get profile_delete_blocked_title;

  /// Cuerpo del bloqueo por rodada activa
  ///
  /// In es, this message translates to:
  /// **'Eres el organizador de una rodada que aún no termina. Si borras tu cuenta ahora, quienes se inscribieron se quedan sin quién responda.'**
  String get profile_delete_blocked_body;

  /// Título de las opciones del bloqueo
  ///
  /// In es, this message translates to:
  /// **'Para poder borrarla'**
  String get profile_delete_blocked_what_title;

  /// Opción: cancelar la rodada
  ///
  /// In es, this message translates to:
  /// **'Cancela la rodada, o'**
  String get profile_delete_blocked_option_cancel_event;

  /// Opción: esperar a que termine
  ///
  /// In es, this message translates to:
  /// **'espera a que termine y vuelve acá'**
  String get profile_delete_blocked_option_wait;

  /// Botón para ver la rodada bloqueante
  ///
  /// In es, this message translates to:
  /// **'Ver la rodada'**
  String get profile_delete_blocked_view_event;

  /// Botón para volver al perfil desde el bloqueo
  ///
  /// In es, this message translates to:
  /// **'Volver al perfil'**
  String get profile_delete_blocked_back_to_profile;

  /// Título de error al borrar la cuenta
  ///
  /// In es, this message translates to:
  /// **'No pudimos borrar tu cuenta'**
  String get profile_delete_error_title;

  /// Cuerpo de error al borrar la cuenta
  ///
  /// In es, this message translates to:
  /// **'Algo falló de nuestro lado. Tu cuenta sigue activa. Inténtalo de nuevo.'**
  String get profile_delete_error_body;

  /// Título de la lista de rodadas
  ///
  /// In es, this message translates to:
  /// **'Rodadas'**
  String get events_list_title;

  /// Segmento de rodadas próximas
  ///
  /// In es, this message translates to:
  /// **'Próximas'**
  String get events_segment_upcoming;

  /// Segmento de rodadas propias (organizadas o inscritas)
  ///
  /// In es, this message translates to:
  /// **'Mías'**
  String get events_segment_mine;

  /// Título del estado vacío de la lista de rodadas
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay rodadas'**
  String get events_list_empty_title;

  /// Cuerpo del estado vacío de la lista de rodadas
  ///
  /// In es, this message translates to:
  /// **'Crea la primera o vuelve cuando alguien publique una cerca de ti.'**
  String get events_list_empty_body;

  /// Cuerpo del estado vacío del segmento Mías
  ///
  /// In es, this message translates to:
  /// **'Organiza una rodada o inscríbete a una para verla aquí.'**
  String get events_list_mine_empty_body;

  /// CTA del estado vacío de la lista de rodadas
  ///
  /// In es, this message translates to:
  /// **'Crear rodada'**
  String get events_list_empty_cta;

  /// Título de error de la lista de rodadas
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar las rodadas'**
  String get events_list_error_title;

  /// Cuerpo sin conexión de la lista de rodadas
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar las rodadas. Revisa tu conexión e inténtalo de nuevo.'**
  String get events_list_offline_body;

  /// Precio de una rodada gratuita en la tarjeta
  ///
  /// In es, this message translates to:
  /// **'Gratis'**
  String get events_card_free;

  /// Dificultad fácil
  ///
  /// In es, this message translates to:
  /// **'Fácil'**
  String get events_difficulty_easy;

  /// Dificultad media
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get events_difficulty_medium;

  /// Dificultad difícil
  ///
  /// In es, this message translates to:
  /// **'Difícil'**
  String get events_difficulty_hard;

  /// Punto de encuentro en el detalle
  ///
  /// In es, this message translates to:
  /// **'Punto de encuentro: {point}'**
  String events_detail_meeting_point(String point);

  /// Etiqueta de sección destino
  ///
  /// In es, this message translates to:
  /// **'DESTINO'**
  String get events_detail_destination_label;

  /// Etiqueta de sección ruta
  ///
  /// In es, this message translates to:
  /// **'RUTA'**
  String get events_detail_route_label;

  /// Botón para abrir el destino en la app de mapas
  ///
  /// In es, this message translates to:
  /// **'Abrir en Waze/Maps'**
  String get events_detail_open_maps;

  /// Nombre del organizador en el detalle
  ///
  /// In es, this message translates to:
  /// **'Organiza {name}'**
  String events_detail_organizer_prefix(String name);

  /// Cupos ocupados con límite
  ///
  /// In es, this message translates to:
  /// **'{approved} de {max} cupos ocupados'**
  String events_detail_spots(int approved, int max);

  /// Cupos ocupados sin límite
  ///
  /// In es, this message translates to:
  /// **'{approved} inscritos'**
  String events_detail_spots_unlimited(int approved);

  /// CTA para inscribirse a una rodada
  ///
  /// In es, this message translates to:
  /// **'Inscribirme'**
  String get events_detail_register_cta;

  /// Insignia de inscripción confirmada
  ///
  /// In es, this message translates to:
  /// **'Inscrito'**
  String get events_detail_registered_badge;

  /// CTA para cancelar la inscripción propia
  ///
  /// In es, this message translates to:
  /// **'Cancelar inscripción'**
  String get events_detail_cancel_registration_cta;

  /// CTA del organizador para iniciar la rodada
  ///
  /// In es, this message translates to:
  /// **'Iniciar rodada'**
  String get events_detail_start_cta;

  /// CTA del organizador para avisar un cambio de ruta
  ///
  /// In es, this message translates to:
  /// **'Cambiar ruta'**
  String get events_detail_change_route_cta;

  /// CTA del organizador para ver inscritos
  ///
  /// In es, this message translates to:
  /// **'Ver inscritos'**
  String get events_detail_view_registrants_cta;

  /// CTA del organizador para cancelar la rodada
  ///
  /// In es, this message translates to:
  /// **'Cancelar rodada'**
  String get events_detail_cancel_event_cta;

  /// Título de confirmación al cancelar una rodada
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar esta rodada?'**
  String get events_detail_cancel_event_confirm_title;

  /// Cuerpo de confirmación al cancelar una rodada
  ///
  /// In es, this message translates to:
  /// **'Se avisará a todos los inscritos. Esta acción no se puede deshacer.'**
  String get events_detail_cancel_event_confirm_body;

  /// CTA de confirmación al cancelar una rodada
  ///
  /// In es, this message translates to:
  /// **'Sí, cancelar rodada'**
  String get events_detail_cancel_event_confirm_cta;

  /// Título de confirmación al cancelar la inscripción propia
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar tu inscripción?'**
  String get events_detail_cancel_registration_confirm_title;

  /// Cuerpo de confirmación al cancelar la inscripción propia
  ///
  /// In es, this message translates to:
  /// **'Perderás tu cupo en esta rodada.'**
  String get events_detail_cancel_registration_confirm_body;

  /// CTA para no confirmar una acción destructiva
  ///
  /// In es, this message translates to:
  /// **'No, mantener'**
  String get events_detail_confirm_keep;

  /// Etiqueta de sección de cambios de ruta en el detalle
  ///
  /// In es, this message translates to:
  /// **'AVISOS DE RUTA'**
  String get events_detail_route_changes_title;

  /// Título de error del detalle de rodada
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar la rodada'**
  String get events_detail_error_title;

  /// Título del banner de aviso de inicio atrasado
  ///
  /// In es, this message translates to:
  /// **'Tu rodada debía empezar a las {time}'**
  String events_detail_start_overdue_title(String time);

  /// Cuerpo del banner de aviso de inicio atrasado
  ///
  /// In es, this message translates to:
  /// **'Los inscritos ya están esperando. Inícia la rodada o avísales si se retrasa.'**
  String get events_detail_start_overdue_body;

  /// Insignia de rodada cancelada
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get events_detail_cancelled_badge;

  /// Insignia de rodada finalizada
  ///
  /// In es, this message translates to:
  /// **'Finalizada'**
  String get events_detail_finished_badge;

  /// Título del asistente de creación de rodada
  ///
  /// In es, this message translates to:
  /// **'Nueva rodada'**
  String get events_create_title;

  /// Indicador de paso del asistente
  ///
  /// In es, this message translates to:
  /// **'Paso {step} de 3'**
  String events_create_step_label(int step);

  /// Título del paso 1 del asistente
  ///
  /// In es, this message translates to:
  /// **'Crea tu rodada'**
  String get events_create_step1_title;

  /// CTA para agregar foto de portada
  ///
  /// In es, this message translates to:
  /// **'Agregar foto de portada'**
  String get events_create_photo_cta;

  /// Label del campo nombre
  ///
  /// In es, this message translates to:
  /// **'Nombre de la rodada'**
  String get events_create_name_label;

  /// Hint del campo nombre
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo: Rodada al Nevado del Ruiz'**
  String get events_create_name_hint;

  /// Label del campo fecha y hora
  ///
  /// In es, this message translates to:
  /// **'Fecha y hora'**
  String get events_create_datetime_label;

  /// Placeholder del campo fecha y hora
  ///
  /// In es, this message translates to:
  /// **'Selecciona fecha y hora'**
  String get events_create_datetime_placeholder;

  /// Label del campo punto de encuentro
  ///
  /// In es, this message translates to:
  /// **'Punto de encuentro'**
  String get events_create_meeting_point_label;

  /// Hint del campo punto de encuentro
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo: Estación Terpel Sur, Autopista Sur'**
  String get events_create_meeting_point_hint;

  /// CTA para avanzar de paso en el asistente
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get events_create_next_cta;

  /// Título del paso 2 del asistente
  ///
  /// In es, this message translates to:
  /// **'¿A dónde van?'**
  String get events_create_step2_title;

  /// Label del buscador de destino
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get events_create_destination_label;

  /// Hint del buscador de destino
  ///
  /// In es, this message translates to:
  /// **'Busca un lugar o escribe la dirección'**
  String get events_create_destination_hint;

  /// Label del campo de ruta en texto
  ///
  /// In es, this message translates to:
  /// **'Ruta (texto)'**
  String get events_create_route_label;

  /// Hint del campo de ruta en texto
  ///
  /// In es, this message translates to:
  /// **'Describe el trayecto: por dónde salen, por dónde regresan'**
  String get events_create_route_hint;

  /// Label del selector de dificultad
  ///
  /// In es, this message translates to:
  /// **'Dificultad'**
  String get events_create_difficulty_label;

  /// Título del paso 3 del asistente
  ///
  /// In es, this message translates to:
  /// **'Cupos y precio'**
  String get events_create_step3_title;

  /// Label del campo de cupos
  ///
  /// In es, this message translates to:
  /// **'Cupos disponibles'**
  String get events_create_spots_label;

  /// Sufijo del campo de cupos
  ///
  /// In es, this message translates to:
  /// **'personas'**
  String get events_create_spots_suffix;

  /// Ayuda del campo de cupos
  ///
  /// In es, this message translates to:
  /// **'Máximo de riders que pueden inscribirse'**
  String get events_create_spots_hint;

  /// Label del switch de rodada gratuita
  ///
  /// In es, this message translates to:
  /// **'Rodada gratis'**
  String get events_create_free_label;

  /// Ayuda del switch de rodada gratuita
  ///
  /// In es, this message translates to:
  /// **'Sin costo para los inscritos'**
  String get events_create_free_subtitle;

  /// Label del campo de precio
  ///
  /// In es, this message translates to:
  /// **'Precio (COP)'**
  String get events_create_price_label;

  /// Etiqueta de la sección resumen
  ///
  /// In es, this message translates to:
  /// **'RESUMEN'**
  String get events_create_summary_label;

  /// Fila resumen: nombre
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get events_create_summary_name;

  /// Fila resumen: fecha
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get events_create_summary_date;

  /// Fila resumen: precio
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get events_create_summary_price;

  /// CTA final para publicar la rodada
  ///
  /// In es, this message translates to:
  /// **'Publicar rodada'**
  String get events_create_publish_cta;

  /// Estado del botón mientras se publica
  ///
  /// In es, this message translates to:
  /// **'Publicando…'**
  String get events_create_saving;

  /// Subtítulo mientras se publica o hay error
  ///
  /// In es, this message translates to:
  /// **'Todo esto es opcional. Puedes guardar así.'**
  String get events_create_saving_subtitle;

  /// Título de error al publicar
  ///
  /// In es, this message translates to:
  /// **'No pudimos publicar la rodada'**
  String get events_create_error_title;

  /// Cuerpo de error al publicar
  ///
  /// In es, this message translates to:
  /// **'Revisa tu conexión e inténtalo de nuevo. Tus datos siguen aquí.'**
  String get events_create_error_body;

  /// Título de la pantalla de inscripción
  ///
  /// In es, this message translates to:
  /// **'Inscripción'**
  String get events_register_title;

  /// Etiqueta de sección de datos propios
  ///
  /// In es, this message translates to:
  /// **'TUS DATOS'**
  String get events_register_your_data_label;

  /// Fila de datos: nombre
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get events_register_name_field;

  /// Fila de datos: teléfono
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get events_register_phone_field;

  /// Fila de datos: tipo de sangre
  ///
  /// In es, this message translates to:
  /// **'Tipo de sangre'**
  String get events_register_blood_type_field;

  /// Fila de datos: EPS
  ///
  /// In es, this message translates to:
  /// **'EPS'**
  String get events_register_eps_field;

  /// Fila de datos: contacto de emergencia
  ///
  /// In es, this message translates to:
  /// **'Contacto de emergencia'**
  String get events_register_emergency_contact_field;

  /// Valor de una fila de datos sin diligenciar
  ///
  /// In es, this message translates to:
  /// **'Sin registrar'**
  String get events_register_not_provided;

  /// Nota para editar el perfil desde la inscripción
  ///
  /// In es, this message translates to:
  /// **'¿Algo desactualizado? Corrígelo en tu perfil.'**
  String get events_register_edit_profile_note;

  /// Etiqueta de sección de permisos
  ///
  /// In es, this message translates to:
  /// **'PERMISOS'**
  String get events_register_permissions_label;

  /// Switch de compartir datos médicos
  ///
  /// In es, this message translates to:
  /// **'Compartir mis datos médicos con el organizador'**
  String get events_register_share_medical_label;

  /// Ayuda del switch de datos médicos
  ///
  /// In es, this message translates to:
  /// **'Tipo de sangre y EPS, solo si hay una emergencia'**
  String get events_register_share_medical_subtitle;

  /// Switch de permitir contacto del organizador
  ///
  /// In es, this message translates to:
  /// **'Permitir que el organizador me contacte'**
  String get events_register_allow_contact_label;

  /// Ayuda del switch de permitir contacto
  ///
  /// In es, this message translates to:
  /// **'Solo antes y durante la rodada'**
  String get events_register_allow_contact_subtitle;

  /// Etiqueta de sección de aceptación de riesgos
  ///
  /// In es, this message translates to:
  /// **'ACEPTACIÓN DE RIESGOS'**
  String get events_register_risk_label;

  /// Texto de aceptación de riesgos
  ///
  /// In es, this message translates to:
  /// **'Entiendo que rodar tiene riesgos y participo bajo mi propia responsabilidad.'**
  String get events_register_risk_text;

  /// Nota de versión de términos y edad mínima
  ///
  /// In es, this message translates to:
  /// **'Términos de participación v1.0 · edad mínima 18 años'**
  String get events_register_risk_terms;

  /// Label del selector de moto en la inscripción
  ///
  /// In es, this message translates to:
  /// **'Moto'**
  String get events_register_vehicle_label;

  /// Placa vacía en el selector de moto
  ///
  /// In es, this message translates to:
  /// **'Sin placa registrada'**
  String get events_register_no_vehicle_plate;

  /// CTA para confirmar la inscripción
  ///
  /// In es, this message translates to:
  /// **'Confirmar inscripción'**
  String get events_register_confirm_cta;

  /// Título del estado de perfil incompleto
  ///
  /// In es, this message translates to:
  /// **'Completa tu perfil antes de inscribirte'**
  String get events_register_incomplete_title;

  /// Cuerpo del estado de perfil incompleto
  ///
  /// In es, this message translates to:
  /// **'El organizador necesita tu teléfono y tu contacto de emergencia para poder ayudarte en la vía.'**
  String get events_register_incomplete_body;

  /// CTA para ir a completar el perfil
  ///
  /// In es, this message translates to:
  /// **'Completar perfil'**
  String get events_register_incomplete_cta;

  /// Error de edad mínima al inscribirse
  ///
  /// In es, this message translates to:
  /// **'Debes ser mayor de 18 años para inscribirte a una rodada.'**
  String get events_register_underage_error;

  /// Error de inscripción duplicada
  ///
  /// In es, this message translates to:
  /// **'Ya estás inscrito en esta rodada.'**
  String get events_register_already_registered_error;

  /// Error genérico de inscripción
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar tu inscripción. Inténtalo de nuevo.'**
  String get events_register_generic_error;

  /// Título de la pantalla de inscritos con cupo máximo
  ///
  /// In es, this message translates to:
  /// **'Inscritos · {approved}/{max}'**
  String events_registrants_title(int approved, int max);

  /// Título de la pantalla de inscritos sin cupo máximo
  ///
  /// In es, this message translates to:
  /// **'Inscritos · {approved}'**
  String events_registrants_title_unlimited(int approved);

  /// CTA para llamar a un inscrito
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get events_registrants_call;

  /// CTA para llamar al contacto de emergencia de un inscrito
  ///
  /// In es, this message translates to:
  /// **'Contacto de emergencia'**
  String get events_registrants_call_emergency;

  /// Título del estado vacío de inscritos
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay inscritos'**
  String get events_registrants_empty_title;

  /// Cuerpo del estado vacío de inscritos
  ///
  /// In es, this message translates to:
  /// **'Cuando alguien se inscriba, lo verás aquí.'**
  String get events_registrants_empty_body;

  /// Título de error de la pantalla de inscritos
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar los inscritos'**
  String get events_registrants_error_title;

  /// Título de la hoja de cambio de ruta
  ///
  /// In es, this message translates to:
  /// **'Cambiar la ruta'**
  String get events_route_change_title;

  /// Cuerpo de la hoja de cambio de ruta
  ///
  /// In es, this message translates to:
  /// **'Se lo avisamos a los {count} inscritos apenas guardes.'**
  String events_route_change_body(int count);

  /// Label del campo de nueva ruta
  ///
  /// In es, this message translates to:
  /// **'Nueva ruta'**
  String get events_route_change_field_label;

  /// CTA para avisar el cambio de ruta
  ///
  /// In es, this message translates to:
  /// **'Avisar a los inscritos'**
  String get events_route_change_cta;

  /// Título de la notificación persistente del tracking en segundo plano (D14)
  ///
  /// In es, this message translates to:
  /// **'Compartiendo tu ubicación con la rodada'**
  String get live_notification_title;

  /// Cuerpo de la notificación persistente del tracking en segundo plano
  ///
  /// In es, this message translates to:
  /// **'Toca Detener para dejar de compartir'**
  String get live_notification_body;

  /// Botón de la notificación persistente que para el tracking (D14)
  ///
  /// In es, this message translates to:
  /// **'Detener'**
  String get live_notification_stop_button;

  /// Error: el usuario no es participante aprobado de la rodada
  ///
  /// In es, this message translates to:
  /// **'No estás inscrito en esta rodada, así que no podemos mostrarte esto.'**
  String get live_ride_error_not_a_participant;

  /// Error: la rodada no está en estado started
  ///
  /// In es, this message translates to:
  /// **'Esta rodada todavía no arrancó.'**
  String get live_ride_error_event_not_started;

  /// Error: el sos_id no existe
  ///
  /// In es, this message translates to:
  /// **'No encontramos esa alerta de SOS.'**
  String get live_ride_error_sos_not_found;

  /// Error: D19, solo el emisor o el organizador cierran un SOS
  ///
  /// In es, this message translates to:
  /// **'Solo quien lanzó el SOS o el organizador pueden cerrarlo.'**
  String get live_ride_error_not_allowed_to_close;

  /// Error: permiso de ubicación denegado al intentar compartir
  ///
  /// In es, this message translates to:
  /// **'Necesitamos tu ubicación para compartirla con la rodada. Actívala desde los ajustes del sistema.'**
  String get live_ride_error_location_permission_denied;

  /// Error: servicio de ubicación del sistema apagado
  ///
  /// In es, this message translates to:
  /// **'Tu GPS está apagado. Actívalo para compartir tu ubicación.'**
  String get live_ride_error_location_service_disabled;

  /// Error: ni una lectura fresca ni la última conocida están disponibles
  ///
  /// In es, this message translates to:
  /// **'No pudimos obtener tu ubicación. Muévete a un lugar con mejor señal de GPS e inténtalo de nuevo.'**
  String get live_ride_error_location_unavailable;

  /// Error: sin conectividad al llamar al servidor de tracking en vivo
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu señal e inténtalo de nuevo.'**
  String get live_ride_error_offline;

  /// Error genérico de live_ride sin código específico
  ///
  /// In es, this message translates to:
  /// **'Algo falló con la rodada en vivo. Inténtalo de nuevo.'**
  String get live_ride_error_generic;

  /// Título de la hoja de riders de LV1
  ///
  /// In es, this message translates to:
  /// **'Riders en la rodada ({count})'**
  String live_ride_riders_sheet_title(int count);

  /// CTA para empezar a compartir ubicación (LV1b)
  ///
  /// In es, this message translates to:
  /// **'Compartir mi ubicación'**
  String get live_ride_share_cta;

  /// Chip del header mientras se comparte ubicación
  ///
  /// In es, this message translates to:
  /// **'Compartiendo ubicación'**
  String get live_ride_sharing_chip;

  /// Botón para dejar de compartir ubicación
  ///
  /// In es, this message translates to:
  /// **'Detener'**
  String get live_ride_stop_cta;

  /// Sufijo junto al propio nombre en la lista de riders
  ///
  /// In es, this message translates to:
  /// **'(tú)'**
  String get live_ride_me_suffix;

  /// Sufijo junto al nombre del organizador/líder en la lista de riders
  ///
  /// In es, this message translates to:
  /// **'Líder'**
  String get live_ride_leader_suffix;

  /// Estado de un rider que no está compartiendo ubicación
  ///
  /// In es, this message translates to:
  /// **'No comparte su ubicación'**
  String get live_ride_not_sharing_status;

  /// Tooltip/label del icono de riders del header de LV1 (solo organizador)
  ///
  /// In es, this message translates to:
  /// **'Ver riders'**
  String get live_ride_riders_header_action;

  /// Distancia en metros a un rider
  ///
  /// In es, this message translates to:
  /// **'A {meters} m'**
  String live_distance_meters(int meters);

  /// Distancia en kilómetros a un rider, ya formateada con coma decimal
  ///
  /// In es, this message translates to:
  /// **'A {km} km'**
  String live_distance_km(String km);

  /// Frescura de una posición recién recibida
  ///
  /// In es, this message translates to:
  /// **'Hace menos de 1 min'**
  String get live_freshness_now;

  /// Frescura de una posición reciente
  ///
  /// In es, this message translates to:
  /// **'Hace {minutes} min'**
  String live_freshness_minutes(int minutes);

  /// Frescura de una posición vieja (D20: solo información, nunca alarma)
  ///
  /// In es, this message translates to:
  /// **'Sin señal hace {minutes} min'**
  String live_freshness_stale_minutes(int minutes);

  /// LV1 sin permiso: título
  ///
  /// In es, this message translates to:
  /// **'Necesitamos tu ubicación'**
  String get live_ride_permission_title;

  /// LV1 sin permiso: cuerpo
  ///
  /// In es, this message translates to:
  /// **'Sin permiso de ubicación no podemos mostrarte la rodada ni compartir la tuya con el grupo. Actívalo en los ajustes del teléfono.'**
  String get live_ride_permission_body;

  /// LV1 sin permiso: CTA principal
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get live_ride_permission_open_settings_cta;

  /// LV1 sin permiso: CTA secundario
  ///
  /// In es, this message translates to:
  /// **'Ya lo activé, reintentar'**
  String get live_ride_permission_retry_cta;

  /// LV1 sin GPS: título
  ///
  /// In es, this message translates to:
  /// **'No encontramos señal de GPS'**
  String get live_ride_no_gps_title;

  /// LV1 sin GPS: cuerpo
  ///
  /// In es, this message translates to:
  /// **'Verifica que el GPS de tu teléfono esté encendido. En túneles o zonas de montaña puede tardar un poco en ubicarte.'**
  String get live_ride_no_gps_body;

  /// LV1 sin GPS: CTA principal
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes de ubicación'**
  String get live_ride_no_gps_open_settings_cta;

  /// LV1 sin GPS: CTA secundario
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get live_ride_no_gps_retry_cta;

  /// LV1 sin conexión: cuerpo
  ///
  /// In es, this message translates to:
  /// **'No pudimos actualizar la rodada en vivo. Revisa tu conexión e inténtalo de nuevo.'**
  String get live_ride_offline_body;

  /// LV1 error: título
  ///
  /// In es, this message translates to:
  /// **'Algo falló'**
  String get live_ride_error_title;

  /// LV7: título
  ///
  /// In es, this message translates to:
  /// **'La rodada terminó'**
  String get live_ride_finished_title;

  /// LV7: cuerpo
  ///
  /// In es, this message translates to:
  /// **'Se dejó de compartir tu ubicación con el grupo.'**
  String get live_ride_finished_body;

  /// LV7: CTA
  ///
  /// In es, this message translates to:
  /// **'Volver al evento'**
  String get live_ride_finished_cta;

  /// LV7 con SOS abierto: línea de estado de la rodada
  ///
  /// In es, this message translates to:
  /// **'La rodada terminó. Se dejó de compartir tu ubicación.'**
  String get live_ride_finished_status_line;

  /// LV7 con SOS abierto: título del aviso
  ///
  /// In es, this message translates to:
  /// **'Tu alerta SOS sigue activa'**
  String get live_ride_finished_sos_title;

  /// LV7 con SOS abierto: cuerpo del aviso
  ///
  /// In es, this message translates to:
  /// **'El grupo la sigue viendo aunque la rodada haya terminado. Ciérrala solo cuando estés bien.'**
  String get live_ride_finished_sos_body;

  /// LV2: título de la hoja de consentimiento
  ///
  /// In es, this message translates to:
  /// **'Compartir tu ubicación con el grupo'**
  String get live_ride_consent_title;

  /// LV2: fila informativa
  ///
  /// In es, this message translates to:
  /// **'Solo la ven los inscritos en esta rodada.'**
  String get live_ride_consent_row_participants;

  /// LV2: fila informativa
  ///
  /// In es, this message translates to:
  /// **'Solo se comparte mientras la rodada está en curso.'**
  String get live_ride_consent_row_duration;

  /// LV2: fila informativa
  ///
  /// In es, this message translates to:
  /// **'Para cuando quieras: botón Detener y notificación persistente.'**
  String get live_ride_consent_row_stop;

  /// LV2: CTA principal
  ///
  /// In es, this message translates to:
  /// **'Permitir'**
  String get live_ride_consent_allow_cta;

  /// LV2/LV2b: CTA secundario
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get live_ride_consent_dismiss_cta;

  /// LV2b: título
  ///
  /// In es, this message translates to:
  /// **'Compartir tu ubicación todo el tiempo'**
  String get live_ride_consent_always_title;

  /// LV2b: fila informativa
  ///
  /// In es, this message translates to:
  /// **'Verás una notificación mientras compartas, para saber que sigue activa.'**
  String get live_ride_consent_always_row_notification;

  /// LV2b: fila informativa
  ///
  /// In es, this message translates to:
  /// **'Sin este permiso, tu posición deja de actualizarse al bloquear la pantalla.'**
  String get live_ride_consent_always_row_lock;

  /// LV2b: CTA principal
  ///
  /// In es, this message translates to:
  /// **'Permitir todo el tiempo'**
  String get live_ride_consent_always_allow_cta;

  /// Banner de advertencia cuando el rider comparte solo mientras la app está abierta
  ///
  /// In es, this message translates to:
  /// **'Sin permiso de ubicación en segundo plano: si bloqueas la pantalla, se deja de compartir.'**
  String get live_ride_background_permission_banner;

  /// Etiqueta del botón flotante de SOS sobre el mapa
  ///
  /// In es, this message translates to:
  /// **'SOS'**
  String get sos_button_label;

  /// LV3: título de la hoja
  ///
  /// In es, this message translates to:
  /// **'¿Pedir ayuda al grupo?'**
  String get sos_confirm_title;

  /// LV3: cuerpo de la hoja
  ///
  /// In es, this message translates to:
  /// **'Avisaremos a los riders de esta rodada con tu ubicación. No llama a emergencias.'**
  String get sos_confirm_body;

  /// LV3: etiqueta dentro del botón de mantener pulsado
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsado para enviar'**
  String get sos_confirm_hold_label;

  /// LV3: CTA cancelar
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get sos_confirm_cancel_cta;

  /// LV4a/b: título del header
  ///
  /// In es, this message translates to:
  /// **'SOS activo'**
  String get sos_active_header_title;

  /// LV4a: título de estado
  ///
  /// In es, this message translates to:
  /// **'Alerta pendiente'**
  String get sos_pending_title;

  /// LV4a: cuerpo de estado
  ///
  /// In es, this message translates to:
  /// **'Sin señal. Tu alerta se enviará al recuperar cobertura.'**
  String get sos_pending_body;

  /// LV4a: chip de estado
  ///
  /// In es, this message translates to:
  /// **'Enviando cuando haya señal'**
  String get sos_pending_chip;

  /// Estado transitorio entre pulsar SOS y tener respuesta del outbox
  ///
  /// In es, this message translates to:
  /// **'Enviando tu alerta'**
  String get sos_sending_title;

  /// LV4b: título de estado
  ///
  /// In es, this message translates to:
  /// **'El grupo ya sabe dónde estás'**
  String get sos_confirmed_title;

  /// LV4b: cuerpo de estado
  ///
  /// In es, this message translates to:
  /// **'El servidor confirmó tu alerta. El grupo ya puede ver tu ubicación.'**
  String get sos_confirmed_body;

  /// LV4b: chip de estado
  ///
  /// In es, this message translates to:
  /// **'Alerta confirmada'**
  String get sos_confirmed_chip;

  /// Estado tras cerrar el propio SOS
  ///
  /// In es, this message translates to:
  /// **'Tu SOS está cerrado'**
  String get sos_closed_title;

  /// Cuerpo del estado cerrado
  ///
  /// In es, this message translates to:
  /// **'El grupo ya no ve tu alerta activa.'**
  String get sos_closed_body;

  /// Precisión de la posición del SOS
  ///
  /// In es, this message translates to:
  /// **'Precisión ±{meters} m'**
  String sos_coordinates_precision(int meters);

  /// CTA de fallback D17: llamar al contacto de emergencia cacheado
  ///
  /// In es, this message translates to:
  /// **'Llamar a mi contacto · {name}'**
  String sos_call_contact_cta(String name);

  /// CTA de fallback cuando no hay contacto de emergencia cacheado
  ///
  /// In es, this message translates to:
  /// **'Llamar al organizador · {name}'**
  String sos_call_organizer_cta(String name);

  /// Aviso cuando no hay ni contacto ni teléfono de organizador
  ///
  /// In es, this message translates to:
  /// **'No tienes un contacto de emergencia guardado. Usa el SMS o llama al organizador.'**
  String get sos_no_contact_warning;

  /// CTA de fallback D17: SMS con coordenadas
  ///
  /// In es, this message translates to:
  /// **'Enviar SMS con mi ubicación'**
  String get sos_sms_cta;

  /// D18: CTA terciario, nunca automático
  ///
  /// In es, this message translates to:
  /// **'Llamar al 123'**
  String get sos_call_123_cta;

  /// CTA para cerrar el propio SOS
  ///
  /// In es, this message translates to:
  /// **'Ya estoy bien — cerrar SOS'**
  String get sos_close_cta;

  /// Diálogo de confirmación al cerrar el propio SOS: título
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar tu SOS?'**
  String get sos_close_confirm_title;

  /// Diálogo de confirmación al cerrar el propio SOS: cuerpo
  ///
  /// In es, this message translates to:
  /// **'Ciérralo solo cuando estés bien de verdad.'**
  String get sos_close_confirm_body;

  /// Diálogo de confirmación al cerrar el propio SOS: CTA
  ///
  /// In es, this message translates to:
  /// **'Sí, estoy bien'**
  String get sos_close_confirm_cta;

  /// Diálogo de confirmación: cancelar
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get sos_close_confirm_cancel;

  /// LV5a: texto del banner rojo persistente
  ///
  /// In es, this message translates to:
  /// **'{name} pidió ayuda · {distance}'**
  String sos_other_banner_title(String name, String distance);

  /// LV5a: CTA del banner
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get sos_other_banner_cta;

  /// LV5b: subtítulo bajo el nombre del rider
  ///
  /// In es, this message translates to:
  /// **'Pidió ayuda · Hace {minutes} min'**
  String sos_other_asked_help_minutes(int minutes);

  /// LV5b: distancia a la alerta
  ///
  /// In es, this message translates to:
  /// **'{distance} de ti'**
  String sos_other_distance_from_me(String distance);

  /// LV5b: CTA de llamar al rider en SOS
  ///
  /// In es, this message translates to:
  /// **'Llamar a {name}'**
  String sos_other_call_cta(String name);

  /// LV5b: CTA de centrar el mapa en la alerta
  ///
  /// In es, this message translates to:
  /// **'Ver en el mapa'**
  String get sos_other_view_map_cta;

  /// LV5b: CTA de cierre, solo visible para el organizador
  ///
  /// In es, this message translates to:
  /// **'Marcar como resuelto · solo organizador'**
  String get sos_other_resolve_cta;

  /// LV5b: nota bajo los CTA
  ///
  /// In es, this message translates to:
  /// **'Solo el organizador o quien pidió ayuda pueden cerrarlo.'**
  String get sos_other_resolve_note;

  /// LV5c: título del diálogo
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar el SOS de {name}?'**
  String sos_other_close_confirm_title(String name);

  /// LV5c: cuerpo del diálogo
  ///
  /// In es, this message translates to:
  /// **'Hazlo solo si confirmaste con {name} que ya está bien.'**
  String sos_other_close_confirm_body(String name);

  /// LV5c: CTA de confirmación
  ///
  /// In es, this message translates to:
  /// **'Sí, está bien'**
  String get sos_other_close_confirm_cta;

  /// LV5c: CTA de cancelar
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get sos_other_close_confirm_cancel;

  /// Sufijo de LV6: la distancia mostrada es respecto al líder, no a mí
  ///
  /// In es, this message translates to:
  /// **'del líder'**
  String get live_ride_leader_distance_suffix;

  /// Título fijo del header de LV6 (el conteo va en el subtítulo)
  ///
  /// In es, this message translates to:
  /// **'Riders'**
  String get live_riders_page_header;

  /// LV6: subtítulo bajo el header
  ///
  /// In es, this message translates to:
  /// **'{count} riders · {sharing} comparten ubicación'**
  String live_riders_page_subtitle(int count, int sharing);

  /// CTA en el detalle de evento (EV2) cuando la rodada está en curso
  ///
  /// In es, this message translates to:
  /// **'Ver rodada en vivo'**
  String get live_ride_view_live_cta;

  /// Banner en el detalle de evento cuando el rider tiene un SOS propio pendiente o confirmado
  ///
  /// In es, this message translates to:
  /// **'Tienes un SOS activo en esta rodada'**
  String get live_ride_own_sos_banner;
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
