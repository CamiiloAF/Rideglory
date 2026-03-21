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

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'Rideglory'**
  String get appName;

  /// No description provided for @accept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get accept;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get add;

  /// No description provided for @apply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get apply;

  /// No description provided for @clear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get clear;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @continue_.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continue_;

  /// No description provided for @openSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get openSettings;

  /// No description provided for @generateWithAI.
  ///
  /// In es, this message translates to:
  /// **'Generar con IA'**
  String get generateWithAI;

  /// No description provided for @photoPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Permiso de galería'**
  String get photoPermissionTitle;

  /// No description provided for @photoPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'Se necesita acceso a la galería para elegir una imagen.'**
  String get photoPermissionDenied;

  /// No description provided for @photoPermissionPermanentlyDenied.
  ///
  /// In es, this message translates to:
  /// **'El acceso a la galería está desactivado. Actívalo en Ajustes para subir una imagen.'**
  String get photoPermissionPermanentlyDenied;

  /// No description provided for @exit.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get exit;

  /// No description provided for @exitAppTitle.
  ///
  /// In es, this message translates to:
  /// **'Salir de la aplicación'**
  String get exitAppTitle;

  /// No description provided for @exitAppMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas salir de Rideglory?'**
  String get exitAppMessage;

  /// No description provided for @errorOccurred.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error'**
  String get errorOccurred;

  /// No description provided for @tryAgain.
  ///
  /// In es, this message translates to:
  /// **'Intentar nuevamente'**
  String get tryAgain;

  /// No description provided for @noInternet.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión a internet'**
  String get noInternet;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Permiso de ubicación'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionMapRequiredMessage.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos acceso a tu ubicación para mostrar tu posición y seguir la rodada en vivo. Puedes continuar usando la app sin este permiso, pero el mapa en vivo no estará disponible.'**
  String get locationPermissionMapRequiredMessage;

  /// No description provided for @imageUploadFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo subir la imagen. Revisa tu conexión e intenta de nuevo.'**
  String get imageUploadFailed;

  /// No description provided for @imageUploadCancelled.
  ///
  /// In es, this message translates to:
  /// **'La subida de la imagen fue cancelada.'**
  String get imageUploadCancelled;

  /// No description provided for @imageUploadNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la subida. Intenta de nuevo en unos segundos.'**
  String get imageUploadNotFound;

  /// No description provided for @noData.
  ///
  /// In es, this message translates to:
  /// **'No hay datos'**
  String get noData;

  /// No description provided for @noResults.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron resultados'**
  String get noResults;

  /// No description provided for @noSearchResultsHint.
  ///
  /// In es, this message translates to:
  /// **'Intenta ajustar los filtros o la búsqueda'**
  String get noSearchResultsHint;

  /// No description provided for @notAvailable.
  ///
  /// In es, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @noSearchResults.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron resultados para tu búsqueda'**
  String get noSearchResults;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @pleaseWait.
  ///
  /// In es, this message translates to:
  /// **'Por favor espera'**
  String get pleaseWait;

  /// No description provided for @success.
  ///
  /// In es, this message translates to:
  /// **'Éxito'**
  String get success;

  /// No description provided for @savedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Guardado exitosamente'**
  String get savedSuccessfully;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Eliminado exitosamente'**
  String get deletedSuccessfully;

  /// No description provided for @updatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Actualizado exitosamente'**
  String get updatedSuccessfully;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings;

  /// No description provided for @comingSoon.
  ///
  /// In es, this message translates to:
  /// **'próximamente'**
  String get comingSoon;

  /// No description provided for @required.
  ///
  /// In es, this message translates to:
  /// **'es requerido'**
  String get required;

  /// No description provided for @mustBeNumber.
  ///
  /// In es, this message translates to:
  /// **'Debe ser un número'**
  String get mustBeNumber;

  /// No description provided for @invalidValue.
  ///
  /// In es, this message translates to:
  /// **'Valor inválido'**
  String get invalidValue;

  /// No description provided for @mustBeGreaterThanZero.
  ///
  /// In es, this message translates to:
  /// **'Debe ser mayor a 0'**
  String get mustBeGreaterThanZero;

  /// No description provided for @mustBeGreaterThan.
  ///
  /// In es, this message translates to:
  /// **'Debe ser mayor a'**
  String get mustBeGreaterThan;

  /// No description provided for @errorMessage.
  ///
  /// In es, this message translates to:
  /// **'Error: {message}'**
  String errorMessage(Object message);

  /// No description provided for @auth_loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get auth_loginTitle;

  /// No description provided for @auth_loginSubtitleStitch.
  ///
  /// In es, this message translates to:
  /// **'Acelera tu experiencia'**
  String get auth_loginSubtitleStitch;

  /// No description provided for @auth_emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get auth_emailLabel;

  /// No description provided for @auth_emailHint.
  ///
  /// In es, this message translates to:
  /// **'nombre@ejemplo.com'**
  String get auth_emailHint;

  /// No description provided for @auth_passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get auth_passwordLabel;

  /// No description provided for @auth_passwordHint.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get auth_passwordHint;

  /// No description provided for @auth_forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get auth_forgotPassword;

  /// No description provided for @auth_signInButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get auth_signInButton;

  /// No description provided for @auth_orContinueWithStitch.
  ///
  /// In es, this message translates to:
  /// **'O continúa con'**
  String get auth_orContinueWithStitch;

  /// No description provided for @auth_noAccountQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes una cuenta?'**
  String get auth_noAccountQuestion;

  /// No description provided for @auth_registerFreeLink.
  ///
  /// In es, this message translates to:
  /// **'Regístrate gratis'**
  String get auth_registerFreeLink;

  /// No description provided for @auth_googleLabel.
  ///
  /// In es, this message translates to:
  /// **'Google'**
  String get auth_googleLabel;

  /// No description provided for @auth_appleLabel.
  ///
  /// In es, this message translates to:
  /// **'Apple'**
  String get auth_appleLabel;

  /// No description provided for @auth_signingInLabel.
  ///
  /// In es, this message translates to:
  /// **'Iniciando sesión...'**
  String get auth_signingInLabel;

  /// No description provided for @auth_registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Únete a la comunidad'**
  String get auth_registerTitle;

  /// No description provided for @auth_registerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta para empezar a rodar con nosotros.'**
  String get auth_registerSubtitle;

  /// No description provided for @auth_registerSignInQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes una cuenta?'**
  String get auth_registerSignInQuestion;

  /// No description provided for @auth_registerSignInLink.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get auth_registerSignInLink;

  /// No description provided for @auth_nameField.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get auth_nameField;

  /// No description provided for @auth_nameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Juan Pérez'**
  String get auth_nameHint;

  /// No description provided for @auth_passwordMinStitch.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get auth_passwordMinStitch;

  /// No description provided for @auth_createAccountButton.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get auth_createAccountButton;

  /// No description provided for @auth_termsPrefix.
  ///
  /// In es, this message translates to:
  /// **'Acepto los '**
  String get auth_termsPrefix;

  /// No description provided for @auth_termsOf.
  ///
  /// In es, this message translates to:
  /// **'Términos'**
  String get auth_termsOf;

  /// No description provided for @auth_termsAnd.
  ///
  /// In es, this message translates to:
  /// **' y '**
  String get auth_termsAnd;

  /// No description provided for @auth_termsConditions.
  ///
  /// In es, this message translates to:
  /// **'Condiciones'**
  String get auth_termsConditions;

  /// No description provided for @auth_termsAnd2.
  ///
  /// In es, this message translates to:
  /// **' y la '**
  String get auth_termsAnd2;

  /// No description provided for @auth_termsPrivacy.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get auth_termsPrivacy;

  /// No description provided for @auth_termsSuffix.
  ///
  /// In es, this message translates to:
  /// **' de MotoConnect.'**
  String get auth_termsSuffix;

  /// No description provided for @auth_letsStart.
  ///
  /// In es, this message translates to:
  /// **'Comencemos'**
  String get auth_letsStart;

  /// No description provided for @auth_loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión o crea una cuenta para gestionar tus vehículos'**
  String get auth_loginSubtitle;

  /// No description provided for @auth_signIn.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get auth_signIn;

  /// No description provided for @auth_signUp.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get auth_signUp;

  /// No description provided for @auth_createAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get auth_createAccount;

  /// No description provided for @auth_joinToday.
  ///
  /// In es, this message translates to:
  /// **'Únete Hoy'**
  String get auth_joinToday;

  /// No description provided for @auth_signupSubtitleSocial.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo crear tu cuenta'**
  String get auth_signupSubtitleSocial;

  /// No description provided for @auth_signupSubtitleEmail.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta con email y contraseña'**
  String get auth_signupSubtitleEmail;

  /// No description provided for @auth_alreadyHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get auth_alreadyHaveAccount;

  /// No description provided for @auth_dontHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get auth_dontHaveAccount;

  /// No description provided for @auth_signUpHere.
  ///
  /// In es, this message translates to:
  /// **'Regístrate aquí'**
  String get auth_signUpHere;

  /// No description provided for @auth_signInHere.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión aquí'**
  String get auth_signInHere;

  /// No description provided for @auth_createAccountLink.
  ///
  /// In es, this message translates to:
  /// **'Crear una'**
  String get auth_createAccountLink;

  /// No description provided for @auth_signInLink.
  ///
  /// In es, this message translates to:
  /// **'aquí'**
  String get auth_signInLink;

  /// No description provided for @auth_orContinueWith.
  ///
  /// In es, this message translates to:
  /// **'O continúa con'**
  String get auth_orContinueWith;

  /// No description provided for @auth_email.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get auth_email;

  /// No description provided for @auth_password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get auth_password;

  /// No description provided for @auth_confirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get auth_confirmPassword;

  /// No description provided for @auth_enterEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingrese su correo electrónico'**
  String get auth_enterEmail;

  /// No description provided for @auth_enterPassword.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get auth_enterPassword;

  /// No description provided for @auth_createPassword.
  ///
  /// In es, this message translates to:
  /// **'Crea una contraseña'**
  String get auth_createPassword;

  /// No description provided for @auth_confirmYourPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu contraseña'**
  String get auth_confirmYourPassword;

  /// No description provided for @auth_emailRequired.
  ///
  /// In es, this message translates to:
  /// **'El email es requerido'**
  String get auth_emailRequired;

  /// No description provided for @auth_invalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Dirección de correo inválida'**
  String get auth_invalidEmail;

  /// No description provided for @auth_passwordRequired.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es requerida'**
  String get auth_passwordRequired;

  /// No description provided for @auth_passwordMinLength.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get auth_passwordMinLength;

  /// No description provided for @auth_passwordMinLength8.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 8 caracteres'**
  String get auth_passwordMinLength8;

  /// No description provided for @auth_passwordNeedsUppercase.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe contener una mayúscula'**
  String get auth_passwordNeedsUppercase;

  /// No description provided for @auth_passwordNeedsNumber.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe contener un número'**
  String get auth_passwordNeedsNumber;

  /// No description provided for @auth_confirmPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Por favor confirma tu contraseña'**
  String get auth_confirmPasswordRequired;

  /// No description provided for @auth_passwordsDoNotMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get auth_passwordsDoNotMatch;

  /// No description provided for @auth_continueWithEmail.
  ///
  /// In es, this message translates to:
  /// **'Continuar con correo'**
  String get auth_continueWithEmail;

  /// No description provided for @auth_continueWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get auth_continueWithGoogle;

  /// No description provided for @auth_continueWithApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get auth_continueWithApple;

  /// No description provided for @auth_acceptTerms.
  ///
  /// In es, this message translates to:
  /// **'Acepto los '**
  String get auth_acceptTerms;

  /// No description provided for @auth_termsOfService.
  ///
  /// In es, this message translates to:
  /// **'Términos de Servicio'**
  String get auth_termsOfService;

  /// No description provided for @auth_privacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get auth_privacyPolicy;

  /// No description provided for @auth_termsAndConditions.
  ///
  /// In es, this message translates to:
  /// **'términos y condiciones'**
  String get auth_termsAndConditions;

  /// No description provided for @auth_acceptTermsError.
  ///
  /// In es, this message translates to:
  /// **'Por favor acepta los términos y condiciones'**
  String get auth_acceptTermsError;

  /// No description provided for @auth_failedToSignOut.
  ///
  /// In es, this message translates to:
  /// **'Falló al cerrar sesión, intenta de nuevo'**
  String get auth_failedToSignOut;

  /// No description provided for @auth_logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get auth_logout;

  /// No description provided for @auth_logoutConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get auth_logoutConfirmTitle;

  /// No description provided for @auth_logoutConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cerrar sesión?'**
  String get auth_logoutConfirmMessage;

  /// No description provided for @auth_exitLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Salir del inicio de sesión'**
  String get auth_exitLoginTitle;

  /// No description provided for @auth_exitLoginMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas salir?'**
  String get auth_exitLoginMessage;

  /// No description provided for @event_events.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get event_events;

  /// No description provided for @event_myEvents.
  ///
  /// In es, this message translates to:
  /// **'Mis Eventos'**
  String get event_myEvents;

  /// No description provided for @event_createEvent.
  ///
  /// In es, this message translates to:
  /// **'Crear Evento'**
  String get event_createEvent;

  /// No description provided for @event_editEvent.
  ///
  /// In es, this message translates to:
  /// **'Editar Evento'**
  String get event_editEvent;

  /// No description provided for @event_eventDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle del Evento'**
  String get event_eventDetail;

  /// No description provided for @event_deleteEvent.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Evento'**
  String get event_deleteEvent;

  /// No description provided for @event_edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get event_edit;

  /// No description provided for @event_delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get event_delete;

  /// No description provided for @event_startEvent.
  ///
  /// In es, this message translates to:
  /// **'Iniciar evento'**
  String get event_startEvent;

  /// No description provided for @event_stopEvent.
  ///
  /// In es, this message translates to:
  /// **'Detener evento'**
  String get event_stopEvent;

  /// No description provided for @event_stopEventConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Finalizar rodada?'**
  String get event_stopEventConfirmTitle;

  /// No description provided for @event_stopEventConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Se cerrará el seguimiento en vivo para todos los participantes.'**
  String get event_stopEventConfirmMessage;

  /// No description provided for @event_meetingTimePrefix.
  ///
  /// In es, this message translates to:
  /// **'Encuentro: '**
  String get event_meetingTimePrefix;

  /// No description provided for @event_allBrands.
  ///
  /// In es, this message translates to:
  /// **'Todas las marcas'**
  String get event_allBrands;

  /// No description provided for @event_basicInfo.
  ///
  /// In es, this message translates to:
  /// **'Información básica'**
  String get event_basicInfo;

  /// No description provided for @event_dateAndTime.
  ///
  /// In es, this message translates to:
  /// **'Fecha y hora'**
  String get event_dateAndTime;

  /// No description provided for @event_locations.
  ///
  /// In es, this message translates to:
  /// **'Ubicaciones'**
  String get event_locations;

  /// No description provided for @event_eventDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles del evento'**
  String get event_eventDetails;

  /// No description provided for @event_eventName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del evento'**
  String get event_eventName;

  /// No description provided for @event_eventDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get event_eventDescription;

  /// No description provided for @event_eventCity.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get event_eventCity;

  /// No description provided for @event_eventCityHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar ciudad y departamento...'**
  String get event_eventCityHint;

  /// No description provided for @event_startDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de inicio'**
  String get event_startDate;

  /// No description provided for @event_eventNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Rodada de la semana'**
  String get event_eventNameHint;

  /// No description provided for @event_eventNameCannotBeModified.
  ///
  /// In es, this message translates to:
  /// **'El nombre del evento no se puede modificar una vez creado.'**
  String get event_eventNameCannotBeModified;

  /// No description provided for @event_endDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de fin (opcional)'**
  String get event_endDate;

  /// No description provided for @event_dateRange.
  ///
  /// In es, this message translates to:
  /// **'Rango de fechas del evento'**
  String get event_dateRange;

  /// No description provided for @event_isMultiDay.
  ///
  /// In es, this message translates to:
  /// **'Es un evento de varios días'**
  String get event_isMultiDay;

  /// No description provided for @event_meetingTime.
  ///
  /// In es, this message translates to:
  /// **'Hora de encuentro'**
  String get event_meetingTime;

  /// No description provided for @event_difficulty.
  ///
  /// In es, this message translates to:
  /// **'Dificultad'**
  String get event_difficulty;

  /// No description provided for @event_rideDifficulty.
  ///
  /// In es, this message translates to:
  /// **'Dificultad de la Ruta'**
  String get event_rideDifficulty;

  /// No description provided for @event_eventType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de evento'**
  String get event_eventType;

  /// No description provided for @event_finalDestination.
  ///
  /// In es, this message translates to:
  /// **'Destino final'**
  String get event_finalDestination;

  /// No description provided for @event_searchBrandsPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Escribe para buscar marcas...'**
  String get event_searchBrandsPlaceholder;

  /// No description provided for @event_meetingPoint.
  ///
  /// In es, this message translates to:
  /// **'Punto de encuentro'**
  String get event_meetingPoint;

  /// No description provided for @event_meetingPointHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Parque principal, Cra 5 #10-20'**
  String get event_meetingPointHint;

  /// No description provided for @event_meetingPointLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación del punto de encuentro'**
  String get event_meetingPointLocation;

  /// No description provided for @event_destination.
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get event_destination;

  /// No description provided for @event_latitude.
  ///
  /// In es, this message translates to:
  /// **'Latitud'**
  String get event_latitude;

  /// No description provided for @event_longitude.
  ///
  /// In es, this message translates to:
  /// **'Longitud'**
  String get event_longitude;

  /// No description provided for @event_isMultiBrand.
  ///
  /// In es, this message translates to:
  /// **'Evento multimarca (abierto a todos)'**
  String get event_isMultiBrand;

  /// No description provided for @event_allowedBrands.
  ///
  /// In es, this message translates to:
  /// **'Marcas permitidas'**
  String get event_allowedBrands;

  /// No description provided for @event_allowedBrandsHint.
  ///
  /// In es, this message translates to:
  /// **'Honda, Yamaha, Kawasaki...'**
  String get event_allowedBrandsHint;

  /// No description provided for @event_allowedBrandsHelper.
  ///
  /// In es, this message translates to:
  /// **'Separar con coma. Dejar vacío si acepta todas las marcas.'**
  String get event_allowedBrandsHelper;

  /// No description provided for @event_addBrand.
  ///
  /// In es, this message translates to:
  /// **'Agregar marca'**
  String get event_addBrand;

  /// No description provided for @event_price.
  ///
  /// In es, this message translates to:
  /// **'Precio del evento (opcional)'**
  String get event_price;

  /// No description provided for @event_priceHint.
  ///
  /// In es, this message translates to:
  /// **'0 para evento gratuito'**
  String get event_priceHint;

  /// No description provided for @event_freeEvent.
  ///
  /// In es, this message translates to:
  /// **'Evento gratuito'**
  String get event_freeEvent;

  /// No description provided for @event_startDateMustBeBeforeEndDate.
  ///
  /// In es, this message translates to:
  /// **'La fecha de inicio debe ser anterior a la fecha de fin'**
  String get event_startDateMustBeBeforeEndDate;

  /// No description provided for @event_difficultyOne.
  ///
  /// In es, this message translates to:
  /// **'Fácil'**
  String get event_difficultyOne;

  /// No description provided for @event_difficultyTwo.
  ///
  /// In es, this message translates to:
  /// **'Moderado'**
  String get event_difficultyTwo;

  /// No description provided for @event_difficultyThree.
  ///
  /// In es, this message translates to:
  /// **'Intermedio'**
  String get event_difficultyThree;

  /// No description provided for @event_difficultyFour.
  ///
  /// In es, this message translates to:
  /// **'Difícil'**
  String get event_difficultyFour;

  /// No description provided for @event_difficultyFive.
  ///
  /// In es, this message translates to:
  /// **'Muy difícil'**
  String get event_difficultyFive;

  /// No description provided for @event_offRoad.
  ///
  /// In es, this message translates to:
  /// **'Off-Road'**
  String get event_offRoad;

  /// No description provided for @event_onRoad.
  ///
  /// In es, this message translates to:
  /// **'On-Road'**
  String get event_onRoad;

  /// No description provided for @event_exhibition.
  ///
  /// In es, this message translates to:
  /// **'Exhibición'**
  String get event_exhibition;

  /// No description provided for @event_charitable.
  ///
  /// In es, this message translates to:
  /// **'Benéfico'**
  String get event_charitable;

  /// No description provided for @event_saveEvent.
  ///
  /// In es, this message translates to:
  /// **'Guardar Evento'**
  String get event_saveEvent;

  /// No description provided for @event_updateEvent.
  ///
  /// In es, this message translates to:
  /// **'Actualizar Evento'**
  String get event_updateEvent;

  /// No description provided for @event_publishEvent.
  ///
  /// In es, this message translates to:
  /// **'Publicar evento'**
  String get event_publishEvent;

  /// No description provided for @event_newEvent.
  ///
  /// In es, this message translates to:
  /// **'Nuevo evento'**
  String get event_newEvent;

  /// No description provided for @event_publish.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get event_publish;

  /// No description provided for @event_aiSuggestDescription.
  ///
  /// In es, this message translates to:
  /// **'Sugerir con IA'**
  String get event_aiSuggestDescription;

  /// No description provided for @event_addEventCover.
  ///
  /// In es, this message translates to:
  /// **'Agregar portada del evento'**
  String get event_addEventCover;

  /// No description provided for @event_addEventCoverHint.
  ///
  /// In es, this message translates to:
  /// **'Una imagen impactante atrae a más motociclistas. Formatos: JPG, PNG.'**
  String get event_addEventCoverHint;

  /// No description provided for @event_uploadImage.
  ///
  /// In es, this message translates to:
  /// **'Subir imagen'**
  String get event_uploadImage;

  /// No description provided for @event_generateWithAI.
  ///
  /// In es, this message translates to:
  /// **'Generar'**
  String get event_generateWithAI;

  /// No description provided for @event_photoPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'Se necesita acceso a la galería para elegir la portada del evento.'**
  String get event_photoPermissionDenied;

  /// No description provided for @event_photoPermissionPermanentlyDenied.
  ///
  /// In es, this message translates to:
  /// **'El acceso a la galería está desactivado. Actívalo en Ajustes para subir una imagen.'**
  String get event_photoPermissionPermanentlyDenied;

  /// No description provided for @event_openSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get event_openSettings;

  /// No description provided for @event_pickImageError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo seleccionar la imagen.'**
  String get event_pickImageError;

  /// No description provided for @event_originCity.
  ///
  /// In es, this message translates to:
  /// **'Ciudad de origen'**
  String get event_originCity;

  /// No description provided for @event_dateRangeLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha (rango)'**
  String get event_dateRangeLabel;

  /// No description provided for @event_routeAndMap.
  ///
  /// In es, this message translates to:
  /// **'Ruta y mapa'**
  String get event_routeAndMap;

  /// No description provided for @event_meetingPointPreview.
  ///
  /// In es, this message translates to:
  /// **'Vista previa del punto de encuentro'**
  String get event_meetingPointPreview;

  /// No description provided for @event_viewOnMap.
  ///
  /// In es, this message translates to:
  /// **'Ver en mapa'**
  String get event_viewOnMap;

  /// No description provided for @event_multiBrandLabel.
  ///
  /// In es, this message translates to:
  /// **'Multimarca'**
  String get event_multiBrandLabel;

  /// No description provided for @event_multiBrandAllowAny.
  ///
  /// In es, this message translates to:
  /// **'Permitir motos de cualquier fabricante'**
  String get event_multiBrandAllowAny;

  /// No description provided for @event_selectBrands.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar marcas permitidas'**
  String get event_selectBrands;

  /// No description provided for @event_registrationPriceOptional.
  ///
  /// In es, this message translates to:
  /// **'Precio de inscripción (opcional)'**
  String get event_registrationPriceOptional;

  /// No description provided for @event_descriptionAndRecommendations.
  ///
  /// In es, this message translates to:
  /// **'Descripción y recomendaciones'**
  String get event_descriptionAndRecommendations;

  /// No description provided for @event_descriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos de qué trata esta rodada, el ritmo, qué equipo llevar y qué esperar...'**
  String get event_descriptionHint;

  /// No description provided for @event_eventCreatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Evento creado exitosamente'**
  String get event_eventCreatedSuccess;

  /// No description provided for @event_eventUpdatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Evento actualizado exitosamente'**
  String get event_eventUpdatedSuccess;

  /// No description provided for @event_eventDeletedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Evento eliminado exitosamente'**
  String get event_eventDeletedSuccess;

  /// No description provided for @event_deleteEventMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este evento?\nEsta acción no se puede deshacer.'**
  String get event_deleteEventMessage;

  /// No description provided for @event_noEvents.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos disponibles'**
  String get event_noEvents;

  /// No description provided for @event_noEventsDescription.
  ///
  /// In es, this message translates to:
  /// **'Sé el primero en crear un evento para la comunidad'**
  String get event_noEventsDescription;

  /// No description provided for @event_noMyEvents.
  ///
  /// In es, this message translates to:
  /// **'No has creado eventos'**
  String get event_noMyEvents;

  /// No description provided for @event_noMyEventsDescription.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primer evento y compártelo con la comunidad'**
  String get event_noMyEventsDescription;

  /// No description provided for @event_searchEvents.
  ///
  /// In es, this message translates to:
  /// **'Buscar eventos'**
  String get event_searchEvents;

  /// No description provided for @event_filters.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get event_filters;

  /// No description provided for @event_applyFilters.
  ///
  /// In es, this message translates to:
  /// **'Aplicar filtros'**
  String get event_applyFilters;

  /// No description provided for @event_clearFilters.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtros'**
  String get event_clearFilters;

  /// No description provided for @event_filterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get event_filterAll;

  /// No description provided for @event_searchRegistrations.
  ///
  /// In es, this message translates to:
  /// **'Buscar inscripciones'**
  String get event_searchRegistrations;

  /// No description provided for @event_filterByType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de evento'**
  String get event_filterByType;

  /// No description provided for @event_filterByDifficulty.
  ///
  /// In es, this message translates to:
  /// **'Dificultad'**
  String get event_filterByDifficulty;

  /// No description provided for @event_filterByCity.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get event_filterByCity;

  /// No description provided for @event_filterByDateRange.
  ///
  /// In es, this message translates to:
  /// **'Rango de fechas'**
  String get event_filterByDateRange;

  /// No description provided for @event_filterByFreeOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo eventos gratuitos'**
  String get event_filterByFreeOnly;

  /// No description provided for @event_filterByMultiBrand.
  ///
  /// In es, this message translates to:
  /// **'Solo multimarca'**
  String get event_filterByMultiBrand;

  /// No description provided for @event_filterByStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get event_filterByStatus;

  /// No description provided for @event_aboutTheRide.
  ///
  /// In es, this message translates to:
  /// **'Sobre la rodada'**
  String get event_aboutTheRide;

  /// No description provided for @event_organizedBy.
  ///
  /// In es, this message translates to:
  /// **'Organizado por'**
  String get event_organizedBy;

  /// No description provided for @event_organizerPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'el creador'**
  String get event_organizerPlaceholder;

  /// No description provided for @event_totalParticipation.
  ///
  /// In es, this message translates to:
  /// **'Total participación'**
  String get event_totalParticipation;

  /// No description provided for @event_registerMe.
  ///
  /// In es, this message translates to:
  /// **'Inscribirme'**
  String get event_registerMe;

  /// No description provided for @event_viewMap.
  ///
  /// In es, this message translates to:
  /// **'Ver mapa'**
  String get event_viewMap;

  /// No description provided for @event_creatorRecommendations.
  ///
  /// In es, this message translates to:
  /// **'RECOMENDACIONES DEL CREADOR'**
  String get event_creatorRecommendations;

  /// No description provided for @event_allowedBrandsTitle.
  ///
  /// In es, this message translates to:
  /// **'Marcas Permitidas'**
  String get event_allowedBrandsTitle;

  /// No description provided for @event_allBrandsChip.
  ///
  /// In es, this message translates to:
  /// **'+ Todas'**
  String get event_allBrandsChip;

  /// No description provided for @event_comingSoonPill.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMAMENTE'**
  String get event_comingSoonPill;

  /// No description provided for @event_joinEvent.
  ///
  /// In es, this message translates to:
  /// **'Inscribirse'**
  String get event_joinEvent;

  /// No description provided for @event_editRegistration.
  ///
  /// In es, this message translates to:
  /// **'Editar inscripción'**
  String get event_editRegistration;

  /// No description provided for @event_cancelRegistration.
  ///
  /// In es, this message translates to:
  /// **'Cancelar inscripción'**
  String get event_cancelRegistration;

  /// No description provided for @event_viewRecommendations.
  ///
  /// In es, this message translates to:
  /// **'Ver recomendaciones'**
  String get event_viewRecommendations;

  /// No description provided for @event_viewAttendees.
  ///
  /// In es, this message translates to:
  /// **'Ver inscritos'**
  String get event_viewAttendees;

  /// No description provided for @event_openInMaps.
  ///
  /// In es, this message translates to:
  /// **'Abrir en Google Maps'**
  String get event_openInMaps;

  /// No description provided for @event_meetingPointLabel.
  ///
  /// In es, this message translates to:
  /// **'Punto de encuentro'**
  String get event_meetingPointLabel;

  /// No description provided for @event_destinationLabel.
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get event_destinationLabel;

  /// No description provided for @event_comingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get event_comingSoon;

  /// No description provided for @event_eventLiveNow.
  ///
  /// In es, this message translates to:
  /// **'EN VIVO'**
  String get event_eventLiveNow;

  /// No description provided for @event_eventHasStartedTitle.
  ///
  /// In es, this message translates to:
  /// **'Evento en curso'**
  String get event_eventHasStartedTitle;

  /// No description provided for @event_eventHasStartedDescription.
  ///
  /// In es, this message translates to:
  /// **'La rodada ha comenzado. Sigue la ubicación en tiempo real de todos los participantes y no te pierdas nada.'**
  String get event_eventHasStartedDescription;

  /// No description provided for @event_followRideLive.
  ///
  /// In es, this message translates to:
  /// **'Seguir rodada en vivo'**
  String get event_followRideLive;

  /// No description provided for @event_eventFinished.
  ///
  /// In es, this message translates to:
  /// **'Finalizado'**
  String get event_eventFinished;

  /// No description provided for @event_dateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get event_dateLabel;

  /// No description provided for @event_priceLabel.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get event_priceLabel;

  /// No description provided for @event_free.
  ///
  /// In es, this message translates to:
  /// **'Gratuito'**
  String get event_free;

  /// No description provided for @event_eventCardPriceFree.
  ///
  /// In es, this message translates to:
  /// **'Gratis'**
  String get event_eventCardPriceFree;

  /// No description provided for @event_eventCardMyEvent.
  ///
  /// In es, this message translates to:
  /// **'Mi evento'**
  String get event_eventCardMyEvent;

  /// No description provided for @event_difficultyLabel.
  ///
  /// In es, this message translates to:
  /// **'Dificultad'**
  String get event_difficultyLabel;

  /// No description provided for @event_typeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get event_typeLabel;

  /// No description provided for @event_organizer.
  ///
  /// In es, this message translates to:
  /// **'Organizador'**
  String get event_organizer;

  /// No description provided for @event_brandRestriction.
  ///
  /// In es, this message translates to:
  /// **'Marcas'**
  String get event_brandRestriction;

  /// No description provided for @event_openToAllBrands.
  ///
  /// In es, this message translates to:
  /// **'Abierto a todos'**
  String get event_openToAllBrands;

  /// No description provided for @event_pending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get event_pending;

  /// No description provided for @event_approved.
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get event_approved;

  /// No description provided for @event_rejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get event_rejected;

  /// No description provided for @event_cancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get event_cancelled;

  /// No description provided for @event_readyForEdit.
  ///
  /// In es, this message translates to:
  /// **'Listo para editar'**
  String get event_readyForEdit;

  /// No description provided for @event_pendingDescription.
  ///
  /// In es, this message translates to:
  /// **'Tu inscripción está pendiente de aprobación'**
  String get event_pendingDescription;

  /// No description provided for @event_approvedDescription.
  ///
  /// In es, this message translates to:
  /// **'¡Tu inscripción fue aprobada!'**
  String get event_approvedDescription;

  /// No description provided for @event_rejectedDescription.
  ///
  /// In es, this message translates to:
  /// **'Tu inscripción fue rechazada. No puedes volver a inscribirte a este evento.'**
  String get event_rejectedDescription;

  /// No description provided for @event_cancelledDescription.
  ///
  /// In es, this message translates to:
  /// **'Cancelaste tu inscripción.'**
  String get event_cancelledDescription;

  /// No description provided for @event_readyForEditDescription.
  ///
  /// In es, this message translates to:
  /// **'El organizador habilitó la edición de tu inscripción.'**
  String get event_readyForEditDescription;

  /// No description provided for @event_attendees.
  ///
  /// In es, this message translates to:
  /// **'Inscritos'**
  String get event_attendees;

  /// No description provided for @event_participants.
  ///
  /// In es, this message translates to:
  /// **'Participantes'**
  String get event_participants;

  /// No description provided for @event_attendeesCount.
  ///
  /// In es, this message translates to:
  /// **'personas inscritas'**
  String get event_attendeesCount;

  /// No description provided for @event_approveRegistration.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get event_approveRegistration;

  /// No description provided for @event_rejectRegistration.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get event_rejectRegistration;

  /// No description provided for @event_setReadyForEdit.
  ///
  /// In es, this message translates to:
  /// **'Habilitar edición'**
  String get event_setReadyForEdit;

  /// No description provided for @event_contactAttendee.
  ///
  /// In es, this message translates to:
  /// **'Contactar'**
  String get event_contactAttendee;

  /// No description provided for @event_callAttendee.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get event_callAttendee;

  /// No description provided for @event_emailAttendee.
  ///
  /// In es, this message translates to:
  /// **'Enviar correo'**
  String get event_emailAttendee;

  /// No description provided for @event_whatsappAttendee.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get event_whatsappAttendee;

  /// No description provided for @event_noAttendees.
  ///
  /// In es, this message translates to:
  /// **'No hay inscritos aún'**
  String get event_noAttendees;

  /// No description provided for @event_newRequestsSection.
  ///
  /// In es, this message translates to:
  /// **'NUEVAS SOLICITUDES'**
  String get event_newRequestsSection;

  /// No description provided for @event_pendingBadgeSuffix.
  ///
  /// In es, this message translates to:
  /// **'PENDIENTES'**
  String get event_pendingBadgeSuffix;

  /// No description provided for @event_processedSection.
  ///
  /// In es, this message translates to:
  /// **'YA PROCESADOS'**
  String get event_processedSection;

  /// No description provided for @event_allProcessed.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get event_allProcessed;

  /// No description provided for @event_approvedBadge.
  ///
  /// In es, this message translates to:
  /// **'APROBADO'**
  String get event_approvedBadge;

  /// No description provided for @event_rejectedBadge.
  ///
  /// In es, this message translates to:
  /// **'RECHAZADO'**
  String get event_rejectedBadge;

  /// No description provided for @event_searchAttendees.
  ///
  /// In es, this message translates to:
  /// **'Buscar participantes'**
  String get event_searchAttendees;

  /// No description provided for @event_filterAttendees.
  ///
  /// In es, this message translates to:
  /// **'Filtrar participantes'**
  String get event_filterAttendees;

  /// No description provided for @event_cancelRegistrationTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelar inscripción'**
  String get event_cancelRegistrationTitle;

  /// No description provided for @event_cancelRegistrationMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cancelar tu inscripción? Esta acción no se puede deshacer. Podrás inscribirte nuevamente en cualquier momento.'**
  String get event_cancelRegistrationMessage;

  /// No description provided for @event_cancelRegistrationSuccess.
  ///
  /// In es, this message translates to:
  /// **'Tu inscripción fue cancelada exitosamente'**
  String get event_cancelRegistrationSuccess;

  /// No description provided for @event_errorLoadingEvents.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar los eventos'**
  String get event_errorLoadingEvents;

  /// No description provided for @event_errorSavingEvent.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar el evento'**
  String get event_errorSavingEvent;

  /// No description provided for @event_errorDeletingEvent.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar el evento'**
  String get event_errorDeletingEvent;

  /// No description provided for @event_nameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre es requerido'**
  String get event_nameRequired;

  /// No description provided for @event_descriptionRequired.
  ///
  /// In es, this message translates to:
  /// **'La descripción es requerida'**
  String get event_descriptionRequired;

  /// No description provided for @event_cityRequired.
  ///
  /// In es, this message translates to:
  /// **'La ciudad es requerida'**
  String get event_cityRequired;

  /// No description provided for @event_dateRangeRequired.
  ///
  /// In es, this message translates to:
  /// **'Las fechas del evento son requeridas'**
  String get event_dateRangeRequired;

  /// No description provided for @event_startDateRequired.
  ///
  /// In es, this message translates to:
  /// **'La fecha de inicio es requerida'**
  String get event_startDateRequired;

  /// No description provided for @event_meetingTimeRequired.
  ///
  /// In es, this message translates to:
  /// **'La hora de encuentro es requerida'**
  String get event_meetingTimeRequired;

  /// No description provided for @event_meetingPointRequired.
  ///
  /// In es, this message translates to:
  /// **'El punto de encuentro es requerido'**
  String get event_meetingPointRequired;

  /// No description provided for @event_destinationRequired.
  ///
  /// In es, this message translates to:
  /// **'El destino es requerido'**
  String get event_destinationRequired;

  /// No description provided for @event_difficultyRequired.
  ///
  /// In es, this message translates to:
  /// **'La dificultad es requerida'**
  String get event_difficultyRequired;

  /// No description provided for @event_eventTypeRequired.
  ///
  /// In es, this message translates to:
  /// **'El tipo de evento es requerido'**
  String get event_eventTypeRequired;

  /// No description provided for @event_minCharacters.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 3 caracteres'**
  String get event_minCharacters;

  /// No description provided for @event_invalidLatitude.
  ///
  /// In es, this message translates to:
  /// **'Latitud inválida (-90 a 90)'**
  String get event_invalidLatitude;

  /// No description provided for @event_invalidLongitude.
  ///
  /// In es, this message translates to:
  /// **'Longitud inválida (-180 a 180)'**
  String get event_invalidLongitude;

  /// No description provided for @event_invalidPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio inválido'**
  String get event_invalidPrice;

  /// No description provided for @map_liveTrackingTitle.
  ///
  /// In es, this message translates to:
  /// **'Rider Telemetry & Map'**
  String get map_liveTrackingTitle;

  /// No description provided for @map_rideLabelPrefix.
  ///
  /// In es, this message translates to:
  /// **'Rodada: '**
  String get map_rideLabelPrefix;

  /// No description provided for @map_activeRidersChip.
  ///
  /// In es, this message translates to:
  /// **'Activos:'**
  String get map_activeRidersChip;

  /// No description provided for @map_riderTelemetry.
  ///
  /// In es, this message translates to:
  /// **'Rider telemetry'**
  String get map_riderTelemetry;

  /// No description provided for @map_participantsList.
  ///
  /// In es, this message translates to:
  /// **'Lista de participantes'**
  String get map_participantsList;

  /// No description provided for @map_participantsPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Participant List (placeholder)\n\nImplementación próximamente.'**
  String get map_participantsPlaceholder;

  /// No description provided for @map_speed.
  ///
  /// In es, this message translates to:
  /// **'Velocidad'**
  String get map_speed;

  /// No description provided for @map_distance.
  ///
  /// In es, this message translates to:
  /// **'Distancia'**
  String get map_distance;

  /// No description provided for @map_distanceFromYou.
  ///
  /// In es, this message translates to:
  /// **'Desde ti'**
  String get map_distanceFromYou;

  /// No description provided for @map_battery.
  ///
  /// In es, this message translates to:
  /// **'Batería'**
  String get map_battery;

  /// No description provided for @map_sos.
  ///
  /// In es, this message translates to:
  /// **'SOS'**
  String get map_sos;

  /// No description provided for @map_riderLead.
  ///
  /// In es, this message translates to:
  /// **'Lead'**
  String get map_riderLead;

  /// No description provided for @map_riderRole.
  ///
  /// In es, this message translates to:
  /// **'Rider'**
  String get map_riderRole;

  /// No description provided for @map_mockRiderAlex.
  ///
  /// In es, this message translates to:
  /// **'Alex'**
  String get map_mockRiderAlex;

  /// No description provided for @map_mockRiderMarkThompson.
  ///
  /// In es, this message translates to:
  /// **'Mark Thompson'**
  String get map_mockRiderMarkThompson;

  /// No description provided for @map_mockRiderSarahJenkins.
  ///
  /// In es, this message translates to:
  /// **'Sarah Jenkins'**
  String get map_mockRiderSarahJenkins;

  /// No description provided for @map_mockDeviceGarmin1040.
  ///
  /// In es, this message translates to:
  /// **'Garmin Edge 1040'**
  String get map_mockDeviceGarmin1040;

  /// No description provided for @map_mockDeviceGarmin530.
  ///
  /// In es, this message translates to:
  /// **'Garmin Edge 530'**
  String get map_mockDeviceGarmin530;

  /// No description provided for @map_mockDeviceWahooElemnt.
  ///
  /// In es, this message translates to:
  /// **'Wahoo ELEMNT'**
  String get map_mockDeviceWahooElemnt;

  /// No description provided for @maintenance_maintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get maintenance_maintenance;

  /// No description provided for @maintenance_maintenances.
  ///
  /// In es, this message translates to:
  /// **'Mantenimientos'**
  String get maintenance_maintenances;

  /// No description provided for @maintenance_addMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Agregar mantenimiento'**
  String get maintenance_addMaintenance;

  /// No description provided for @maintenance_editMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Editar mantenimiento'**
  String get maintenance_editMaintenance;

  /// No description provided for @maintenance_deleteMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mantenimiento'**
  String get maintenance_deleteMaintenance;

  /// No description provided for @maintenance_maintenanceHistory.
  ///
  /// In es, this message translates to:
  /// **'Ver historial'**
  String get maintenance_maintenanceHistory;

  /// No description provided for @maintenance_reminders.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios'**
  String get maintenance_reminders;

  /// No description provided for @maintenance_maintenanceDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle de mantenimiento'**
  String get maintenance_maintenanceDetail;

  /// No description provided for @maintenance_newRecord.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Registro'**
  String get maintenance_newRecord;

  /// No description provided for @maintenance_editRecord.
  ///
  /// In es, this message translates to:
  /// **'Editar Registro'**
  String get maintenance_editRecord;

  /// No description provided for @maintenance_deleteMaintenanceMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este mantenimiento?\nEsta acción no se puede deshacer.'**
  String get maintenance_deleteMaintenanceMessage;

  /// No description provided for @maintenance_noMaintenances.
  ///
  /// In es, this message translates to:
  /// **'No hay mantenimientos registrados'**
  String get maintenance_noMaintenances;

  /// No description provided for @maintenance_noMaintenancesDescription.
  ///
  /// In es, this message translates to:
  /// **'Comienza a registrar los mantenimientos de tu vehículo para llevar un control completo'**
  String get maintenance_noMaintenancesDescription;

  /// No description provided for @maintenance_receiveMaintenanceAlert.
  ///
  /// In es, this message translates to:
  /// **'Recibe una notificación cuando se acerque el próximo mantenimiento'**
  String get maintenance_receiveMaintenanceAlert;

  /// No description provided for @maintenance_mileageAlert.
  ///
  /// In es, this message translates to:
  /// **'Alerta por kilometraje'**
  String get maintenance_mileageAlert;

  /// No description provided for @maintenance_mileageAlertHint.
  ///
  /// In es, this message translates to:
  /// **'Notificar cuando falten 500 km para el mantenimiento'**
  String get maintenance_mileageAlertHint;

  /// No description provided for @maintenance_dateAlert.
  ///
  /// In es, this message translates to:
  /// **'Alerta por fecha'**
  String get maintenance_dateAlert;

  /// No description provided for @maintenance_dateAlertHint.
  ///
  /// In es, this message translates to:
  /// **'Notificar una semana antes de la fecha programada'**
  String get maintenance_dateAlertHint;

  /// No description provided for @maintenance_maintenanceDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento eliminado correctamente'**
  String get maintenance_maintenanceDeletedSuccessfully;

  /// No description provided for @maintenance_errorLoadingRecords.
  ///
  /// In es, this message translates to:
  /// **'Error cargando registros'**
  String get maintenance_errorLoadingRecords;

  /// No description provided for @maintenance_noRecordsYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay registros'**
  String get maintenance_noRecordsYet;

  /// No description provided for @maintenance_maintenanceType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de Mantenimiento'**
  String get maintenance_maintenanceType;

  /// No description provided for @maintenance_maintenanceDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Mantenimiento'**
  String get maintenance_maintenanceDate;

  /// No description provided for @maintenance_maintenanceNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas / Observaciones'**
  String get maintenance_maintenanceNotes;

  /// No description provided for @maintenance_maintenanceCost.
  ///
  /// In es, this message translates to:
  /// **'Costo del Mantenimiento'**
  String get maintenance_maintenanceCost;

  /// No description provided for @maintenance_maintenanceMileage.
  ///
  /// In es, this message translates to:
  /// **'Kilometraje Actual'**
  String get maintenance_maintenanceMileage;

  /// No description provided for @maintenance_nextMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Próximo mantenimiento'**
  String get maintenance_nextMaintenance;

  /// No description provided for @maintenance_nextMaintenanceMileage.
  ///
  /// In es, this message translates to:
  /// **'Kilometraje del próximo mantenimiento'**
  String get maintenance_nextMaintenanceMileage;

  /// No description provided for @maintenance_totalCost.
  ///
  /// In es, this message translates to:
  /// **'Costo total'**
  String get maintenance_totalCost;

  /// No description provided for @maintenance_serviceNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas de servicio'**
  String get maintenance_serviceNotes;

  /// No description provided for @maintenance_estimatedDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha estimada'**
  String get maintenance_estimatedDate;

  /// No description provided for @maintenance_suggested.
  ///
  /// In es, this message translates to:
  /// **'Sugerido'**
  String get maintenance_suggested;

  /// No description provided for @maintenance_routine.
  ///
  /// In es, this message translates to:
  /// **'Rutina'**
  String get maintenance_routine;

  /// No description provided for @maintenance_alertByMileage.
  ///
  /// In es, this message translates to:
  /// **'Por kilometraje'**
  String get maintenance_alertByMileage;

  /// No description provided for @maintenance_alertByDate.
  ///
  /// In es, this message translates to:
  /// **'Por fecha'**
  String get maintenance_alertByDate;

  /// No description provided for @maintenance_mileageAlertBefore.
  ///
  /// In es, this message translates to:
  /// **'500 km antes'**
  String get maintenance_mileageAlertBefore;

  /// No description provided for @maintenance_dateAlertBefore.
  ///
  /// In es, this message translates to:
  /// **'7 días antes'**
  String get maintenance_dateAlertBefore;

  /// No description provided for @maintenance_urgent.
  ///
  /// In es, this message translates to:
  /// **'Urgente'**
  String get maintenance_urgent;

  /// No description provided for @maintenance_urgentOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo urgentes'**
  String get maintenance_urgentOnly;

  /// No description provided for @maintenance_filters.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get maintenance_filters;

  /// No description provided for @maintenance_myVehicles.
  ///
  /// In es, this message translates to:
  /// **'Mis Vehículos'**
  String get maintenance_myVehicles;

  /// No description provided for @maintenance_applyFilters.
  ///
  /// In es, this message translates to:
  /// **'Aplicar filtros'**
  String get maintenance_applyFilters;

  /// No description provided for @maintenance_clearFilters.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtros'**
  String get maintenance_clearFilters;

  /// No description provided for @maintenance_mileage.
  ///
  /// In es, this message translates to:
  /// **'Kilometraje'**
  String get maintenance_mileage;

  /// No description provided for @maintenance_currentMileage.
  ///
  /// In es, this message translates to:
  /// **'Kilometraje Actual'**
  String get maintenance_currentMileage;

  /// No description provided for @maintenance_updateMileage.
  ///
  /// In es, this message translates to:
  /// **'Actualizar kilometraje'**
  String get maintenance_updateMileage;

  /// No description provided for @maintenance_mileageUnit.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get maintenance_mileageUnit;

  /// No description provided for @maintenance_kilometers.
  ///
  /// In es, this message translates to:
  /// **'Kilómetros'**
  String get maintenance_kilometers;

  /// No description provided for @maintenance_miles.
  ///
  /// In es, this message translates to:
  /// **'Millas'**
  String get maintenance_miles;

  /// No description provided for @maintenance_km.
  ///
  /// In es, this message translates to:
  /// **'km'**
  String get maintenance_km;

  /// No description provided for @maintenance_mi.
  ///
  /// In es, this message translates to:
  /// **'mi'**
  String get maintenance_mi;

  /// No description provided for @maintenance_current.
  ///
  /// In es, this message translates to:
  /// **'Actual:'**
  String get maintenance_current;

  /// No description provided for @maintenance_maintenanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento:'**
  String get maintenance_maintenanceLabel;

  /// No description provided for @maintenance_mileageGreaterThanCurrent.
  ///
  /// In es, this message translates to:
  /// **'El kilometraje del mantenimiento es mayor al kilometraje actual del vehículo.'**
  String get maintenance_mileageGreaterThanCurrent;

  /// No description provided for @maintenance_updateVehicleMileageQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas actualizar el kilometraje del vehículo?'**
  String get maintenance_updateVehicleMileageQuestion;

  /// No description provided for @maintenance_monthJan.
  ///
  /// In es, this message translates to:
  /// **'Ene'**
  String get maintenance_monthJan;

  /// No description provided for @maintenance_monthFeb.
  ///
  /// In es, this message translates to:
  /// **'Feb'**
  String get maintenance_monthFeb;

  /// No description provided for @maintenance_monthMar.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get maintenance_monthMar;

  /// No description provided for @maintenance_monthApr.
  ///
  /// In es, this message translates to:
  /// **'Abr'**
  String get maintenance_monthApr;

  /// No description provided for @maintenance_monthMay.
  ///
  /// In es, this message translates to:
  /// **'May'**
  String get maintenance_monthMay;

  /// No description provided for @maintenance_monthJun.
  ///
  /// In es, this message translates to:
  /// **'Jun'**
  String get maintenance_monthJun;

  /// No description provided for @maintenance_monthJul.
  ///
  /// In es, this message translates to:
  /// **'Jul'**
  String get maintenance_monthJul;

  /// No description provided for @maintenance_monthAug.
  ///
  /// In es, this message translates to:
  /// **'Ago'**
  String get maintenance_monthAug;

  /// No description provided for @maintenance_monthSep.
  ///
  /// In es, this message translates to:
  /// **'Sep'**
  String get maintenance_monthSep;

  /// No description provided for @maintenance_monthOct.
  ///
  /// In es, this message translates to:
  /// **'Oct'**
  String get maintenance_monthOct;

  /// No description provided for @maintenance_monthNov.
  ///
  /// In es, this message translates to:
  /// **'Nov'**
  String get maintenance_monthNov;

  /// No description provided for @maintenance_monthDec.
  ///
  /// In es, this message translates to:
  /// **'Dic'**
  String get maintenance_monthDec;

  /// No description provided for @maintenance_addMaintenance_.
  ///
  /// In es, this message translates to:
  /// **'Agregar mantenimiento'**
  String get maintenance_addMaintenance_;

  /// No description provided for @maintenance_addMaintenanceAction.
  ///
  /// In es, this message translates to:
  /// **'Agregar mantenimiento'**
  String get maintenance_addMaintenanceAction;

  /// No description provided for @maintenance_viewHistory.
  ///
  /// In es, this message translates to:
  /// **'Ver historial'**
  String get maintenance_viewHistory;

  /// No description provided for @maintenance_saveMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Guardar Registro'**
  String get maintenance_saveMaintenance;

  /// No description provided for @maintenance_saveOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo guardar'**
  String get maintenance_saveOnly;

  /// No description provided for @maintenance_update.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get maintenance_update;

  /// No description provided for @maintenance_sortBy.
  ///
  /// In es, this message translates to:
  /// **'Ordenar por'**
  String get maintenance_sortBy;

  /// No description provided for @maintenance_maintenanceTypes.
  ///
  /// In es, this message translates to:
  /// **'Tipos de mantenimiento'**
  String get maintenance_maintenanceTypes;

  /// No description provided for @maintenance_vehicles.
  ///
  /// In es, this message translates to:
  /// **'Vehículos'**
  String get maintenance_vehicles;

  /// No description provided for @maintenance_dateRange.
  ///
  /// In es, this message translates to:
  /// **'Rango de fechas'**
  String get maintenance_dateRange;

  /// No description provided for @maintenance_startDate.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get maintenance_startDate;

  /// No description provided for @maintenance_endDate.
  ///
  /// In es, this message translates to:
  /// **'Fin'**
  String get maintenance_endDate;

  /// No description provided for @maintenance_sortByNextMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Próximo mantenimiento'**
  String get maintenance_sortByNextMaintenance;

  /// No description provided for @maintenance_sortByDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de realización'**
  String get maintenance_sortByDate;

  /// No description provided for @maintenance_sortByName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get maintenance_sortByName;

  /// No description provided for @maintenance_urgentOnlyDescription.
  ///
  /// In es, this message translates to:
  /// **'Próximo mantenimiento en 7 días o menos'**
  String get maintenance_urgentOnlyDescription;

  /// No description provided for @maintenance_vehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get maintenance_vehicle;

  /// No description provided for @maintenance_selectVehicle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Vehículo'**
  String get maintenance_selectVehicle;

  /// No description provided for @maintenance_chooseVehicleForMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Elige el vehículo para este mantenimiento'**
  String get maintenance_chooseVehicleForMaintenance;

  /// No description provided for @maintenance_next.
  ///
  /// In es, this message translates to:
  /// **'Próximo'**
  String get maintenance_next;

  /// No description provided for @maintenance_calculateRemainingDistance.
  ///
  /// In es, this message translates to:
  /// **'Calcular distancia restante'**
  String get maintenance_calculateRemainingDistance;

  /// No description provided for @maintenance_maintenanceName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del Mantenimiento'**
  String get maintenance_maintenanceName;

  /// No description provided for @maintenance_nextMaintenanceDate.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMA FECHA'**
  String get maintenance_nextMaintenanceDate;

  /// No description provided for @maintenance_maintenanceDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Servicio'**
  String get maintenance_maintenanceDateLabel;

  /// No description provided for @maintenance_nextMaintenanceMileageLabel.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMO KM'**
  String get maintenance_nextMaintenanceMileageLabel;

  /// No description provided for @maintenance_nameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre es requerido'**
  String get maintenance_nameRequired;

  /// No description provided for @maintenance_minCharacters.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 3 caracteres'**
  String get maintenance_minCharacters;

  /// No description provided for @maintenance_typeRequired.
  ///
  /// In es, this message translates to:
  /// **'El tipo es requerido'**
  String get maintenance_typeRequired;

  /// No description provided for @maintenance_remindersLabel.
  ///
  /// In es, this message translates to:
  /// **'Recibe recordatorios automáticos'**
  String get maintenance_remindersLabel;

  /// No description provided for @maintenance_nextServiceAlerts.
  ///
  /// In es, this message translates to:
  /// **'Alertas de próximo servicio'**
  String get maintenance_nextServiceAlerts;

  /// No description provided for @maintenance_alertsConfiguration.
  ///
  /// In es, this message translates to:
  /// **'Configuración de alertas'**
  String get maintenance_alertsConfiguration;

  /// No description provided for @maintenance_alertsActivatedDesc.
  ///
  /// In es, this message translates to:
  /// **'Las alertas están activadas para este mantenimiento.'**
  String get maintenance_alertsActivatedDesc;

  /// No description provided for @maintenance_searchMaintenances.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre del mantenimiento'**
  String get maintenance_searchMaintenances;

  /// No description provided for @maintenance_allVehicles.
  ///
  /// In es, this message translates to:
  /// **'Todos los vehículos'**
  String get maintenance_allVehicles;

  /// No description provided for @maintenance_recentRecords.
  ///
  /// In es, this message translates to:
  /// **'Registros recientes'**
  String get maintenance_recentRecords;

  /// No description provided for @maintenance_filter.
  ///
  /// In es, this message translates to:
  /// **'Filtrar'**
  String get maintenance_filter;

  /// No description provided for @vehicle_vehicles.
  ///
  /// In es, this message translates to:
  /// **'Vehículos'**
  String get vehicle_vehicles;

  /// No description provided for @vehicle_myVehicles.
  ///
  /// In es, this message translates to:
  /// **'Mis Vehículos'**
  String get vehicle_myVehicles;

  /// No description provided for @vehicle_myGarage.
  ///
  /// In es, this message translates to:
  /// **'Mi Garaje'**
  String get vehicle_myGarage;

  /// No description provided for @vehicle_addVehicle.
  ///
  /// In es, this message translates to:
  /// **'Agregar vehículo'**
  String get vehicle_addVehicle;

  /// No description provided for @vehicle_saveVehicle.
  ///
  /// In es, this message translates to:
  /// **'Guardar vehículo'**
  String get vehicle_saveVehicle;

  /// No description provided for @vehicle_editVehicle.
  ///
  /// In es, this message translates to:
  /// **'Editar vehículo'**
  String get vehicle_editVehicle;

  /// No description provided for @vehicle_deleteVehicle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar vehículo'**
  String get vehicle_deleteVehicle;

  /// No description provided for @vehicle_addMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Agregar mantenimiento'**
  String get vehicle_addMaintenance;

  /// No description provided for @vehicle_selectVehicle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar vehículo'**
  String get vehicle_selectVehicle;

  /// No description provided for @vehicle_changeVehicle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar vehículo'**
  String get vehicle_changeVehicle;

  /// No description provided for @vehicle_setAsMainVehicle.
  ///
  /// In es, this message translates to:
  /// **'Establecer como vehículo principal'**
  String get vehicle_setAsMainVehicle;

  /// No description provided for @vehicle_setAsMain.
  ///
  /// In es, this message translates to:
  /// **'Establecer como principal'**
  String get vehicle_setAsMain;

  /// No description provided for @vehicle_archiveVehicle.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get vehicle_archiveVehicle;

  /// No description provided for @vehicle_unarchiveVehicle.
  ///
  /// In es, this message translates to:
  /// **'Desarchivar'**
  String get vehicle_unarchiveVehicle;

  /// No description provided for @vehicle_deleteVehicleMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar'**
  String get vehicle_deleteVehicleMessage;

  /// No description provided for @vehicle_deleteVehicleWarning.
  ///
  /// In es, this message translates to:
  /// **'Esta acción eliminará todos los mantenimientos asociados a este vehículo y no se podrá deshacer.'**
  String get vehicle_deleteVehicleWarning;

  /// No description provided for @vehicle_vehicleDeleted.
  ///
  /// In es, this message translates to:
  /// **'Vehículo eliminado exitosamente'**
  String get vehicle_vehicleDeleted;

  /// No description provided for @vehicle_vehicleSetAsMain.
  ///
  /// In es, this message translates to:
  /// **'establecido como vehículo principal'**
  String get vehicle_vehicleSetAsMain;

  /// No description provided for @vehicle_vehicleArchived.
  ///
  /// In es, this message translates to:
  /// **'archivado'**
  String get vehicle_vehicleArchived;

  /// No description provided for @vehicle_vehicleUnarchived.
  ///
  /// In es, this message translates to:
  /// **'desarchivado'**
  String get vehicle_vehicleUnarchived;

  /// No description provided for @vehicle_noVehicles.
  ///
  /// In es, this message translates to:
  /// **'No tienes vehículos registrados'**
  String get vehicle_noVehicles;

  /// No description provided for @vehicle_noVehiclesAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay vehículos disponibles'**
  String get vehicle_noVehiclesAvailable;

  /// No description provided for @vehicle_noArchivedVehicles.
  ///
  /// In es, this message translates to:
  /// **'No hay vehículos archivados'**
  String get vehicle_noArchivedVehicles;

  /// No description provided for @vehicle_mainVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo principal'**
  String get vehicle_mainVehicle;

  /// No description provided for @vehicle_thisWillBeMainVehicle.
  ///
  /// In es, this message translates to:
  /// **'Este será tu vehículo principal'**
  String get vehicle_thisWillBeMainVehicle;

  /// No description provided for @vehicle_archivedVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo Archivado'**
  String get vehicle_archivedVehicle;

  /// No description provided for @vehicle_archivedVehicleMessage.
  ///
  /// In es, this message translates to:
  /// **'Este vehículo está archivado. ¿Deseas continuar editándolo?\nSi actualizas su información, el vehículo será desarchivado y volverá a estar disponible en tu lista de vehículos activos.'**
  String get vehicle_archivedVehicleMessage;

  /// No description provided for @vehicle_exitSetup.
  ///
  /// In es, this message translates to:
  /// **'¿Salir de la configuración?'**
  String get vehicle_exitSetup;

  /// No description provided for @vehicle_exitSetupMessage.
  ///
  /// In es, this message translates to:
  /// **'Si sales ahora, perderás el progreso de la configuración del vehículo.'**
  String get vehicle_exitSetupMessage;

  /// No description provided for @vehicle_completeRequiredFields.
  ///
  /// In es, this message translates to:
  /// **'Por favor completa todos los campos requeridos'**
  String get vehicle_completeRequiredFields;

  /// No description provided for @vehicle_searchVehicles.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre, placa o marca'**
  String get vehicle_searchVehicles;

  /// No description provided for @vehicle_vehicleName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del vehículo'**
  String get vehicle_vehicleName;

  /// No description provided for @vehicle_vehicleType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de vehículo'**
  String get vehicle_vehicleType;

  /// No description provided for @vehicle_vehicleBrand.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get vehicle_vehicleBrand;

  /// No description provided for @vehicle_vehicleModel.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get vehicle_vehicleModel;

  /// No description provided for @vehicle_vehicleYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get vehicle_vehicleYear;

  /// No description provided for @vehicle_vehiclePlate.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get vehicle_vehiclePlate;

  /// No description provided for @vehicle_vehicleVin.
  ///
  /// In es, this message translates to:
  /// **'VIN'**
  String get vehicle_vehicleVin;

  /// No description provided for @vehicle_vehicleNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Mi moto negra'**
  String get vehicle_vehicleNameHint;

  /// No description provided for @vehicle_vehicleBrandHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Yamaha'**
  String get vehicle_vehicleBrandHint;

  /// No description provided for @vehicle_vehicleModelHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. MT-07'**
  String get vehicle_vehicleModelHint;

  /// No description provided for @vehicle_vehicleYearHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 2022'**
  String get vehicle_vehicleYearHint;

  /// No description provided for @vehicle_vehiclePlateHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. ABC123'**
  String get vehicle_vehiclePlateHint;

  /// No description provided for @vehicle_vehicleVinHint.
  ///
  /// In es, this message translates to:
  /// **'17 caracteres'**
  String get vehicle_vehicleVinHint;

  /// No description provided for @vehicle_vehiclePhoto.
  ///
  /// In es, this message translates to:
  /// **'Foto del vehículo'**
  String get vehicle_vehiclePhoto;

  /// No description provided for @vehicle_uploadPhoto.
  ///
  /// In es, this message translates to:
  /// **'Subir foto'**
  String get vehicle_uploadPhoto;

  /// No description provided for @vehicle_selectImage.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar imagen'**
  String get vehicle_selectImage;

  /// No description provided for @vehicle_changePhoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get vehicle_changePhoto;

  /// No description provided for @vehicle_viewArchived.
  ///
  /// In es, this message translates to:
  /// **'Ver archivados'**
  String get vehicle_viewArchived;

  /// No description provided for @vehicle_showActiveVehicles.
  ///
  /// In es, this message translates to:
  /// **'Mostrar activos'**
  String get vehicle_showActiveVehicles;

  /// No description provided for @vehicle_addFirstVehicle.
  ///
  /// In es, this message translates to:
  /// **'Agrega tu primer vehículo para comenzar'**
  String get vehicle_addFirstVehicle;

  /// No description provided for @vehicle_adjustSearch.
  ///
  /// In es, this message translates to:
  /// **'Intenta ajustar la búsqueda'**
  String get vehicle_adjustSearch;

  /// No description provided for @vehicle_archiveVehiclesDescription.
  ///
  /// In es, this message translates to:
  /// **'Archiva vehículos que ya no uses'**
  String get vehicle_archiveVehiclesDescription;

  /// No description provided for @vehicle_maintenancesTooltip.
  ///
  /// In es, this message translates to:
  /// **'Mantenimientos'**
  String get vehicle_maintenancesTooltip;

  /// No description provided for @vehicle_addVehicleTooltip.
  ///
  /// In es, this message translates to:
  /// **'Agregar vehículo'**
  String get vehicle_addVehicleTooltip;

  /// No description provided for @vehicle_removeVehicleTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar vehículo'**
  String get vehicle_removeVehicleTooltip;

  /// No description provided for @vehicle_addAnotherVehicleTooltip.
  ///
  /// In es, this message translates to:
  /// **'Agregar otro vehículo'**
  String get vehicle_addAnotherVehicleTooltip;

  /// No description provided for @vehicle_welcome.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido! 🎉'**
  String get vehicle_welcome;

  /// No description provided for @vehicle_addAtLeastOneVehicle.
  ///
  /// In es, this message translates to:
  /// **'Agrega al menos un vehículo para comenzar'**
  String get vehicle_addAtLeastOneVehicle;

  /// No description provided for @vehicle_completeSetup.
  ///
  /// In es, this message translates to:
  /// **'Completar configuración'**
  String get vehicle_completeSetup;

  /// No description provided for @vehicle_nameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre es requerido'**
  String get vehicle_nameRequired;

  /// No description provided for @vehicle_vehicleTypeRequired.
  ///
  /// In es, this message translates to:
  /// **'El tipo de vehículo es requerido'**
  String get vehicle_vehicleTypeRequired;

  /// No description provided for @vehicle_brandRequired.
  ///
  /// In es, this message translates to:
  /// **'La marca es requerida'**
  String get vehicle_brandRequired;

  /// No description provided for @vehicle_brandMustBeFromList.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una marca de la lista de sugerencias'**
  String get vehicle_brandMustBeFromList;

  /// No description provided for @vehicle_yearRequired.
  ///
  /// In es, this message translates to:
  /// **'El año es requerido'**
  String get vehicle_yearRequired;

  /// No description provided for @vehicle_minCharacters.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 3 caracteres'**
  String get vehicle_minCharacters;

  /// No description provided for @vehicle_invalidYear.
  ///
  /// In es, this message translates to:
  /// **'Año inválido'**
  String get vehicle_invalidYear;

  /// No description provided for @vehicle_purchaseDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de compra'**
  String get vehicle_purchaseDate;

  /// No description provided for @vehicle_purchaseDateHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 24/12/2025'**
  String get vehicle_purchaseDateHint;

  /// No description provided for @vehicle_car.
  ///
  /// In es, this message translates to:
  /// **'Carro'**
  String get vehicle_car;

  /// No description provided for @vehicle_motorcycle.
  ///
  /// In es, this message translates to:
  /// **'Moto'**
  String get vehicle_motorcycle;

  /// No description provided for @vehicle_quickInfo.
  ///
  /// In es, this message translates to:
  /// **'Info rápida'**
  String get vehicle_quickInfo;

  /// No description provided for @vehicle_currentMileageLabel.
  ///
  /// In es, this message translates to:
  /// **'Kilometraje actual'**
  String get vehicle_currentMileageLabel;

  /// No description provided for @vehicle_fullSpecs.
  ///
  /// In es, this message translates to:
  /// **'Especificaciones completas'**
  String get vehicle_fullSpecs;

  /// No description provided for @vehicle_garageOverview.
  ///
  /// In es, this message translates to:
  /// **'Resumen del garaje'**
  String get vehicle_garageOverview;

  /// No description provided for @vehicle_total.
  ///
  /// In es, this message translates to:
  /// **'TOTAL'**
  String get vehicle_total;

  /// No description provided for @vehicle_lastRide.
  ///
  /// In es, this message translates to:
  /// **'ÚLTIMO VIAJE'**
  String get vehicle_lastRide;

  /// No description provided for @vehicle_allVehicles.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get vehicle_allVehicles;

  /// No description provided for @vehicle_maintenanceHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial de Registros'**
  String get vehicle_maintenanceHistory;

  /// No description provided for @vehicle_seeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get vehicle_seeAll;

  /// No description provided for @profile_profile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profile_profile;

  /// No description provided for @registration_registrationPageTitle.
  ///
  /// In es, this message translates to:
  /// **'Inscripción al Evento'**
  String get registration_registrationPageTitle;

  /// No description provided for @registration_registrationForm.
  ///
  /// In es, this message translates to:
  /// **'Formulario de inscripción'**
  String get registration_registrationForm;

  /// No description provided for @registration_myRegistrations.
  ///
  /// In es, this message translates to:
  /// **'Mis inscripciones'**
  String get registration_myRegistrations;

  /// No description provided for @registration_editRegistration.
  ///
  /// In es, this message translates to:
  /// **'Editar inscripción'**
  String get registration_editRegistration;

  /// No description provided for @registration_personalData.
  ///
  /// In es, this message translates to:
  /// **'Datos Personales'**
  String get registration_personalData;

  /// No description provided for @registration_medicalInfo.
  ///
  /// In es, this message translates to:
  /// **'Información Médica'**
  String get registration_medicalInfo;

  /// No description provided for @registration_emergencyContactRequired.
  ///
  /// In es, this message translates to:
  /// **'Contacto de emergencia'**
  String get registration_emergencyContactRequired;

  /// No description provided for @registration_vehicleData.
  ///
  /// In es, this message translates to:
  /// **'Datos del Vehículo'**
  String get registration_vehicleData;

  /// No description provided for @registration_personalInfo.
  ///
  /// In es, this message translates to:
  /// **'Información personal'**
  String get registration_personalInfo;

  /// No description provided for @registration_emergencyContact.
  ///
  /// In es, this message translates to:
  /// **'Contacto de emergencia'**
  String get registration_emergencyContact;

  /// No description provided for @registration_vehicleInfo.
  ///
  /// In es, this message translates to:
  /// **'Información del vehículo'**
  String get registration_vehicleInfo;

  /// No description provided for @registration_vehicleRegistered.
  ///
  /// In es, this message translates to:
  /// **'Vehículo registrado'**
  String get registration_vehicleRegistered;

  /// No description provided for @registration_firstName.
  ///
  /// In es, this message translates to:
  /// **'Nombres'**
  String get registration_firstName;

  /// No description provided for @registration_lastName.
  ///
  /// In es, this message translates to:
  /// **'Apellidos'**
  String get registration_lastName;

  /// No description provided for @registration_identificationNumber.
  ///
  /// In es, this message translates to:
  /// **'Identificación'**
  String get registration_identificationNumber;

  /// No description provided for @registration_birthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha Nacimiento'**
  String get registration_birthDate;

  /// No description provided for @registration_phone.
  ///
  /// In es, this message translates to:
  /// **'Celular'**
  String get registration_phone;

  /// No description provided for @registration_email.
  ///
  /// In es, this message translates to:
  /// **'Correo Electrónico'**
  String get registration_email;

  /// No description provided for @registration_residenceCity.
  ///
  /// In es, this message translates to:
  /// **'Ciudad Residencia'**
  String get registration_residenceCity;

  /// No description provided for @registration_eps.
  ///
  /// In es, this message translates to:
  /// **'EPS'**
  String get registration_eps;

  /// No description provided for @registration_medicalInsurance.
  ///
  /// In es, this message translates to:
  /// **'Medicina Prepagada (Opcional)'**
  String get registration_medicalInsurance;

  /// No description provided for @registration_bloodType.
  ///
  /// In es, this message translates to:
  /// **'RH'**
  String get registration_bloodType;

  /// No description provided for @registration_emergencyContactName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo contacto'**
  String get registration_emergencyContactName;

  /// No description provided for @registration_emergencyContactPhone.
  ///
  /// In es, this message translates to:
  /// **'Celular contacto'**
  String get registration_emergencyContactPhone;

  /// No description provided for @registration_vehicleBrand.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get registration_vehicleBrand;

  /// No description provided for @registration_vehicleReference.
  ///
  /// In es, this message translates to:
  /// **'Referencia'**
  String get registration_vehicleReference;

  /// No description provided for @registration_licensePlate.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get registration_licensePlate;

  /// No description provided for @registration_vin.
  ///
  /// In es, this message translates to:
  /// **'VIN (Serial)'**
  String get registration_vin;

  /// No description provided for @registration_firstNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Juan Carlos'**
  String get registration_firstNameHint;

  /// No description provided for @registration_lastNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Pérez Rodriguez'**
  String get registration_lastNameHint;

  /// No description provided for @registration_identificationHint.
  ///
  /// In es, this message translates to:
  /// **'CC/TI/CE'**
  String get registration_identificationHint;

  /// No description provided for @registration_birthDateHint.
  ///
  /// In es, this message translates to:
  /// **'mm/dd/yyyy'**
  String get registration_birthDateHint;

  /// No description provided for @registration_phoneHint.
  ///
  /// In es, this message translates to:
  /// **'300 000 0000'**
  String get registration_phoneHint;

  /// No description provided for @registration_residenceCityHint.
  ///
  /// In es, this message translates to:
  /// **'Busca tu ciudad'**
  String get registration_residenceCityHint;

  /// No description provided for @registration_emailHint.
  ///
  /// In es, this message translates to:
  /// **'usuario@ejemplo.com'**
  String get registration_emailHint;

  /// No description provided for @registration_epsHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre EPS'**
  String get registration_epsHint;

  /// No description provided for @registration_bloodTypeSelect.
  ///
  /// In es, this message translates to:
  /// **'Seleccione'**
  String get registration_bloodTypeSelect;

  /// No description provided for @registration_bloodTypeHint.
  ///
  /// In es, this message translates to:
  /// **'RH'**
  String get registration_bloodTypeHint;

  /// No description provided for @registration_emergencyContactNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. María García'**
  String get registration_emergencyContactNameHint;

  /// No description provided for @registration_emergencyContactPhoneHint.
  ///
  /// In es, this message translates to:
  /// **'300 000 0000'**
  String get registration_emergencyContactPhoneHint;

  /// No description provided for @registration_medicalInsuranceHint.
  ///
  /// In es, this message translates to:
  /// **'Entidad de medicina prepagada'**
  String get registration_medicalInsuranceHint;

  /// No description provided for @registration_vehicleBrandHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Yamaha'**
  String get registration_vehicleBrandHint;

  /// No description provided for @registration_vehicleReferenceHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. MT-09'**
  String get registration_vehicleReferenceHint;

  /// No description provided for @registration_licensePlateHint.
  ///
  /// In es, this message translates to:
  /// **'ABC-12D'**
  String get registration_licensePlateHint;

  /// No description provided for @registration_vinHint.
  ///
  /// In es, this message translates to:
  /// **'17 Caracteres'**
  String get registration_vinHint;

  /// No description provided for @registration_preloadFromVehicle.
  ///
  /// In es, this message translates to:
  /// **'Precargar vehículo'**
  String get registration_preloadFromVehicle;

  /// No description provided for @registration_selectVehicleToPreload.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un vehículo para precargar la información'**
  String get registration_selectVehicleToPreload;

  /// No description provided for @registration_clearForm.
  ///
  /// In es, this message translates to:
  /// **'Limpiar formulario'**
  String get registration_clearForm;

  /// No description provided for @registration_sendRegistration.
  ///
  /// In es, this message translates to:
  /// **'Enviar inscripción'**
  String get registration_sendRegistration;

  /// No description provided for @registration_updateRegistration.
  ///
  /// In es, this message translates to:
  /// **'Actualizar inscripción'**
  String get registration_updateRegistration;

  /// No description provided for @registration_registrationSentSuccess.
  ///
  /// In es, this message translates to:
  /// **'Inscripción enviada exitosamente. Está pendiente de aprobación.'**
  String get registration_registrationSentSuccess;

  /// No description provided for @registration_registrationUpdatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Inscripción actualizada exitosamente.'**
  String get registration_registrationUpdatedSuccess;

  /// No description provided for @registration_registrationCancelledSuccess.
  ///
  /// In es, this message translates to:
  /// **'Inscripción cancelada exitosamente.'**
  String get registration_registrationCancelledSuccess;

  /// No description provided for @registration_noRegistrations.
  ///
  /// In es, this message translates to:
  /// **'No tienes inscripciones'**
  String get registration_noRegistrations;

  /// No description provided for @registration_noRegistrationsDescription.
  ///
  /// In es, this message translates to:
  /// **'Explora los eventos disponibles y únete a la aventura'**
  String get registration_noRegistrationsDescription;

  /// No description provided for @registration_firstNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Los nombres son requeridos'**
  String get registration_firstNameRequired;

  /// No description provided for @registration_lastNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Los apellidos son requeridos'**
  String get registration_lastNameRequired;

  /// No description provided for @registration_idRequired.
  ///
  /// In es, this message translates to:
  /// **'El número de identificación es requerido'**
  String get registration_idRequired;

  /// No description provided for @registration_idInvalidLength.
  ///
  /// In es, this message translates to:
  /// **'La cédula debe tener entre 6 y 10 dígitos (estándar Colombia)'**
  String get registration_idInvalidLength;

  /// No description provided for @registration_birthDateRequired.
  ///
  /// In es, this message translates to:
  /// **'La fecha de nacimiento es requerida'**
  String get registration_birthDateRequired;

  /// No description provided for @registration_phoneRequired.
  ///
  /// In es, this message translates to:
  /// **'El celular es requerido'**
  String get registration_phoneRequired;

  /// No description provided for @registration_phoneInvalidLength.
  ///
  /// In es, this message translates to:
  /// **'El celular debe tener 10 dígitos (estándar Colombia)'**
  String get registration_phoneInvalidLength;

  /// No description provided for @registration_emailRequired.
  ///
  /// In es, this message translates to:
  /// **'El correo electrónico es requerido'**
  String get registration_emailRequired;

  /// No description provided for @registration_emailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico inválido'**
  String get registration_emailInvalid;

  /// No description provided for @registration_residenceCityRequired.
  ///
  /// In es, this message translates to:
  /// **'La ciudad de residencia es requerida'**
  String get registration_residenceCityRequired;

  /// No description provided for @registration_epsRequired.
  ///
  /// In es, this message translates to:
  /// **'La EPS es requerida'**
  String get registration_epsRequired;

  /// No description provided for @registration_bloodTypeRequired.
  ///
  /// In es, this message translates to:
  /// **'El tipo de sangre es requerido'**
  String get registration_bloodTypeRequired;

  /// No description provided for @registration_emergencyContactNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre del contacto de emergencia es requerido'**
  String get registration_emergencyContactNameRequired;

  /// No description provided for @registration_emergencyContactPhoneRequired.
  ///
  /// In es, this message translates to:
  /// **'El celular del contacto de emergencia es requerido'**
  String get registration_emergencyContactPhoneRequired;

  /// No description provided for @registration_emergencyContactPhoneInvalidLength.
  ///
  /// In es, this message translates to:
  /// **'El celular del contacto debe tener 10 dígitos (estándar Colombia)'**
  String get registration_emergencyContactPhoneInvalidLength;

  /// No description provided for @registration_vehicleBrandRequired.
  ///
  /// In es, this message translates to:
  /// **'La marca del vehículo es requerida'**
  String get registration_vehicleBrandRequired;

  /// No description provided for @registration_vehicleReferenceRequired.
  ///
  /// In es, this message translates to:
  /// **'La referencia del vehículo es requerida'**
  String get registration_vehicleReferenceRequired;

  /// No description provided for @registration_licensePlateRequired.
  ///
  /// In es, this message translates to:
  /// **'La placa es requerida'**
  String get registration_licensePlateRequired;

  /// No description provided for @registration_minCharacters.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 2 caracteres'**
  String get registration_minCharacters;

  /// No description provided for @registration_errorLoadingRegistrations.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar las inscripciones'**
  String get registration_errorLoadingRegistrations;

  /// No description provided for @registration_errorSendingRegistration.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar la inscripción'**
  String get registration_errorSendingRegistration;

  /// No description provided for @registration_viewDetail.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle'**
  String get registration_viewDetail;

  /// No description provided for @registration_viewEvent.
  ///
  /// In es, this message translates to:
  /// **'Ver evento'**
  String get registration_viewEvent;

  /// No description provided for @registration_goToEvents.
  ///
  /// In es, this message translates to:
  /// **'Ir a eventos'**
  String get registration_goToEvents;

  /// No description provided for @registration_details.
  ///
  /// In es, this message translates to:
  /// **'Detalles'**
  String get registration_details;

  /// No description provided for @registration_myRegistration.
  ///
  /// In es, this message translates to:
  /// **'Mi registro'**
  String get registration_myRegistration;

  /// No description provided for @registration_reason.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get registration_reason;

  /// No description provided for @registration_reRegister.
  ///
  /// In es, this message translates to:
  /// **'Re-inscribirse'**
  String get registration_reRegister;

  /// No description provided for @registration_registrationDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle de inscripción'**
  String get registration_registrationDetail;

  /// No description provided for @registration_registrationDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de Registro'**
  String get registration_registrationDetailTitle;

  /// No description provided for @registration_requestDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de solicitud'**
  String get registration_requestDetailsTitle;

  /// No description provided for @registration_eventInfo.
  ///
  /// In es, this message translates to:
  /// **'Información del evento'**
  String get registration_eventInfo;

  /// No description provided for @registration_inscriptionDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de inscripción'**
  String get registration_inscriptionDate;

  /// No description provided for @registration_appliedOnPrefix.
  ///
  /// In es, this message translates to:
  /// **'Inscrito el '**
  String get registration_appliedOnPrefix;

  /// No description provided for @registration_errorLoadingEvent.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar el evento'**
  String get registration_errorLoadingEvent;

  /// No description provided for @registration_sectionPersonalInfo.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get registration_sectionPersonalInfo;

  /// No description provided for @registration_sectionHealthSafety.
  ///
  /// In es, this message translates to:
  /// **'Salud y seguridad'**
  String get registration_sectionHealthSafety;

  /// No description provided for @registration_sectionVehicleDetails.
  ///
  /// In es, this message translates to:
  /// **'Datos del vehículo'**
  String get registration_sectionVehicleDetails;

  /// No description provided for @registration_fullNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombres Completos'**
  String get registration_fullNameLabel;

  /// No description provided for @registration_identificationIdLabel.
  ///
  /// In es, this message translates to:
  /// **'Identificación (ID)'**
  String get registration_identificationIdLabel;

  /// No description provided for @registration_birthDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Nacimiento'**
  String get registration_birthDateLabel;

  /// No description provided for @registration_bloodTypeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de Sangre'**
  String get registration_bloodTypeLabel;

  /// No description provided for @registration_epsOrInsuranceLabel.
  ///
  /// In es, this message translates to:
  /// **'EPS / Seguro'**
  String get registration_epsOrInsuranceLabel;

  /// No description provided for @registration_brandModelLabel.
  ///
  /// In es, this message translates to:
  /// **'Marca / Modelo'**
  String get registration_brandModelLabel;

  /// No description provided for @registration_cityLabel.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get registration_cityLabel;

  /// No description provided for @registration_motorcycleLabel.
  ///
  /// In es, this message translates to:
  /// **'Motocicleta'**
  String get registration_motorcycleLabel;

  /// No description provided for @registration_plateLabel.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get registration_plateLabel;

  /// No description provided for @registration_reject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get registration_reject;

  /// No description provided for @registration_approve.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get registration_approve;

  /// No description provided for @registration_cancelRegistration.
  ///
  /// In es, this message translates to:
  /// **'Cancelar inscripción'**
  String get registration_cancelRegistration;

  /// No description provided for @registration_contactLabel.
  ///
  /// In es, this message translates to:
  /// **'Contactar'**
  String get registration_contactLabel;

  /// No description provided for @registration_callLabel.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get registration_callLabel;

  /// No description provided for @registration_whatsappLabel.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get registration_whatsappLabel;

  /// No description provided for @splash_appName.
  ///
  /// In es, this message translates to:
  /// **'RIDEGLORY'**
  String get splash_appName;

  /// No description provided for @splash_appNameRide.
  ///
  /// In es, this message translates to:
  /// **'RIDE'**
  String get splash_appNameRide;

  /// No description provided for @splash_appNameGlory.
  ///
  /// In es, this message translates to:
  /// **'GLORY'**
  String get splash_appNameGlory;

  /// No description provided for @splash_tagline.
  ///
  /// In es, this message translates to:
  /// **'CONNECT. RIDE. EXPLORE.'**
  String get splash_tagline;

  /// No description provided for @splash_initializingLabel.
  ///
  /// In es, this message translates to:
  /// **'INITIALIZING SYSTEMS'**
  String get splash_initializingLabel;

  /// No description provided for @splash_versionLabel.
  ///
  /// In es, this message translates to:
  /// **'VERSION 2.4.0'**
  String get splash_versionLabel;

  /// No description provided for @splash_retryLabel.
  ///
  /// In es, this message translates to:
  /// **'REINTENTAR'**
  String get splash_retryLabel;

  /// No description provided for @splash_errorPrefix.
  ///
  /// In es, this message translates to:
  /// **'Error: '**
  String get splash_errorPrefix;

  /// No description provided for @home_greeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, Rider'**
  String get home_greeting;

  /// No description provided for @home_myGarage.
  ///
  /// In es, this message translates to:
  /// **'Mi garaje'**
  String get home_myGarage;

  /// No description provided for @home_viewAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todas'**
  String get home_viewAll;

  /// No description provided for @home_upcomingRides.
  ///
  /// In es, this message translates to:
  /// **'Próximas rodadas'**
  String get home_upcomingRides;

  /// No description provided for @home_viewAllEvents.
  ///
  /// In es, this message translates to:
  /// **'Ver catálogo completo de eventos'**
  String get home_viewAllEvents;

  /// No description provided for @home_addVehicle.
  ///
  /// In es, this message translates to:
  /// **'Agregar vehículo'**
  String get home_addVehicle;

  /// No description provided for @home_addMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Agregar mantenimiento'**
  String get home_addMaintenance;

  /// No description provided for @home_addEvent.
  ///
  /// In es, this message translates to:
  /// **'Agregar evento'**
  String get home_addEvent;

  /// No description provided for @home_nextOilChange.
  ///
  /// In es, this message translates to:
  /// **'Próximo cambio de aceite en'**
  String get home_nextOilChange;

  /// No description provided for @home_viewDetails.
  ///
  /// In es, this message translates to:
  /// **'Ver detalles'**
  String get home_viewDetails;

  /// No description provided for @home_emptyGarage.
  ///
  /// In es, this message translates to:
  /// **'Sin vehículos en tu garaje'**
  String get home_emptyGarage;

  /// No description provided for @home_emptyGarageDescription.
  ///
  /// In es, this message translates to:
  /// **'Agrega tu primera moto para comenzar'**
  String get home_emptyGarageDescription;

  /// No description provided for @home_emptyEvents.
  ///
  /// In es, this message translates to:
  /// **'Sin rodadas próximas'**
  String get home_emptyEvents;

  /// No description provided for @home_emptyEventsDescription.
  ///
  /// In es, this message translates to:
  /// **'Explora el catálogo de eventos disponibles'**
  String get home_emptyEventsDescription;

  /// No description provided for @event_pendingCountBadge.
  ///
  /// In es, this message translates to:
  /// **'{count} PENDIENTES'**
  String event_pendingCountBadge(Object count);

  /// No description provided for @event_allWithCount.
  ///
  /// In es, this message translates to:
  /// **'Todos ({count})'**
  String event_allWithCount(Object count);

  /// No description provided for @event_timeAgoHours.
  ///
  /// In es, this message translates to:
  /// **'Hace {hours}h'**
  String event_timeAgoHours(Object hours);

  /// No description provided for @event_timeAgoMinutes.
  ///
  /// In es, this message translates to:
  /// **'Hace {minutes}m'**
  String event_timeAgoMinutes(Object minutes);

  /// No description provided for @event_timeAgoDays.
  ///
  /// In es, this message translates to:
  /// **'Hace {days}d'**
  String event_timeAgoDays(Object days);

  /// No description provided for @event_approveConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Aprobar la inscripción de {name}?'**
  String event_approveConfirmMessage(Object name);

  /// No description provided for @event_rejectConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Rechazar la inscripción de {name}?'**
  String event_rejectConfirmMessage(Object name);

  /// No description provided for @event_setReadyForEditConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Habilitar edición para {name}?'**
  String event_setReadyForEditConfirmMessage(Object name);

  /// No description provided for @maintenance_performedOn.
  ///
  /// In es, this message translates to:
  /// **'Completado el {date}'**
  String maintenance_performedOn(Object date);

  /// No description provided for @maintenance_remainingDistance.
  ///
  /// In es, this message translates to:
  /// **'{distance} {unit} restantes'**
  String maintenance_remainingDistance(Object distance, Object unit);

  /// No description provided for @event_difficultyLevel.
  ///
  /// In es, this message translates to:
  /// **'{level, select, 1{Fácil} 2{Moderado} 3{Intermedio} 4{Difícil} 5{Muy difícil} other{Intermedio}}'**
  String event_difficultyLevel(String level);
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
