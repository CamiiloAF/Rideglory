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
