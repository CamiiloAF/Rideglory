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
