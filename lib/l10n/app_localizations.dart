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

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

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

  /// No description provided for @auth_emailHint.
  ///
  /// In es, this message translates to:
  /// **'correo@ejemplo.com'**
  String get auth_emailHint;

  /// No description provided for @auth_orContinueWithStitch.
  ///
  /// In es, this message translates to:
  /// **'O continúa con'**
  String get auth_orContinueWithStitch;

  /// No description provided for @auth_appleLabel.
  ///
  /// In es, this message translates to:
  /// **'Apple'**
  String get auth_appleLabel;

  /// No description provided for @auth_nameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Juan Pérez'**
  String get auth_nameHint;

  /// No description provided for @auth_nameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre completo es requerido'**
  String get auth_nameRequired;

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

  /// No description provided for @auth_termsAndConditions.
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get auth_termsAndConditions;

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

  /// No description provided for @auth_signIn.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get auth_signIn;

  /// No description provided for @auth_signInLink.
  ///
  /// In es, this message translates to:
  /// **'aquí'**
  String get auth_signInLink;

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

  /// No description provided for @event_optionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Opciones del evento'**
  String get event_optionsTitle;

  /// No description provided for @event_editEvent.
  ///
  /// In es, this message translates to:
  /// **'Editar evento'**
  String get event_editEvent;

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

  /// No description provided for @event_requestUnderReview.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud está siendo revisada por el organizador.'**
  String get event_requestUnderReview;

  /// No description provided for @event_registrationRejected.
  ///
  /// In es, this message translates to:
  /// **'Inscripción rechazada'**
  String get event_registrationRejected;

  /// No description provided for @event_rejectedMessage.
  ///
  /// In es, this message translates to:
  /// **'El organizador no aprobó tu solicitud para este evento.'**
  String get event_rejectedMessage;

  /// No description provided for @event_eventCancelled.
  ///
  /// In es, this message translates to:
  /// **'Evento cancelado'**
  String get event_eventCancelled;

  /// No description provided for @event_cancelledMessage.
  ///
  /// In es, this message translates to:
  /// **'Este evento fue cancelado por el organizador.'**
  String get event_cancelledMessage;

  /// No description provided for @event_participantsReady.
  ///
  /// In es, this message translates to:
  /// **'Participantes listos para iniciar'**
  String get event_participantsReady;

  /// No description provided for @event_rideInProgress.
  ///
  /// In es, this message translates to:
  /// **'Rodada en progreso'**
  String get event_rideInProgress;

  /// No description provided for @event_saveDraft.
  ///
  /// In es, this message translates to:
  /// **'Guardar borrador'**
  String get event_saveDraft;

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

  /// No description provided for @event_brandsActiveHint.
  ///
  /// In es, this message translates to:
  /// **'Marcas activas — toca para agregar o quitar:'**
  String get event_brandsActiveHint;

  /// No description provided for @event_eventName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del evento'**
  String get event_eventName;

  /// No description provided for @event_filterDateHint.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar'**
  String get event_filterDateHint;

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

  /// No description provided for @event_popularBrands.
  ///
  /// In es, this message translates to:
  /// **'Marcas populares'**
  String get event_popularBrands;

  /// No description provided for @event_searchBrandsPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar otras marcas...'**
  String get event_searchBrandsPlaceholder;

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

  /// No description provided for @event_price.
  ///
  /// In es, this message translates to:
  /// **'Precio del evento (opcional)'**
  String get event_price;

  /// No description provided for @event_startDateMustBeBeforeEndDate.
  ///
  /// In es, this message translates to:
  /// **'La fecha de inicio debe ser anterior a la fecha de fin'**
  String get event_startDateMustBeBeforeEndDate;

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

  /// No description provided for @event_coverSectionLabel.
  ///
  /// In es, this message translates to:
  /// **'PORTADA'**
  String get event_coverSectionLabel;

  /// No description provided for @event_form_eventName.
  ///
  /// In es, this message translates to:
  /// **'NOMBRE DEL EVENTO'**
  String get event_form_eventName;

  /// No description provided for @event_form_dateTimeSectionLabel.
  ///
  /// In es, this message translates to:
  /// **'FECHA Y HORA'**
  String get event_form_dateTimeSectionLabel;

  /// No description provided for @event_form_dateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get event_form_dateLabel;

  /// No description provided for @event_form_timeLabel.
  ///
  /// In es, this message translates to:
  /// **'Hora de inicio'**
  String get event_form_timeLabel;

  /// No description provided for @event_form_datePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar fecha...'**
  String get event_form_datePlaceholder;

  /// No description provided for @event_form_timePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar hora...'**
  String get event_form_timePlaceholder;

  /// No description provided for @event_addEventCover.
  ///
  /// In es, this message translates to:
  /// **'Agregar portada'**
  String get event_addEventCover;

  /// No description provided for @event_addEventCoverHint.
  ///
  /// In es, this message translates to:
  /// **'JPG · PNG · 1200×628'**
  String get event_addEventCoverHint;

  /// No description provided for @event_uploadImage.
  ///
  /// In es, this message translates to:
  /// **'Subir imagen'**
  String get event_uploadImage;

  /// No description provided for @event_route.
  ///
  /// In es, this message translates to:
  /// **'PUNTOS DE RUTA'**
  String get event_route;

  /// No description provided for @event_route_required_error.
  ///
  /// In es, this message translates to:
  /// **'Debes agregar al menos un punto de ruta para continuar.'**
  String get event_route_required_error;

  /// No description provided for @event_image_required_error.
  ///
  /// In es, this message translates to:
  /// **'La imagen de portada es obligatoria para publicar el evento.'**
  String get event_image_required_error;

  /// No description provided for @event_multiBrandLabel.
  ///
  /// In es, this message translates to:
  /// **'Marcas permitidas'**
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

  /// No description provided for @event_showMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get event_showMore;

  /// No description provided for @event_showLess.
  ///
  /// In es, this message translates to:
  /// **'Ver menos'**
  String get event_showLess;

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

  /// No description provided for @event_viewAttendees.
  ///
  /// In es, this message translates to:
  /// **'Ver inscritos'**
  String get event_viewAttendees;

  /// No description provided for @event_viewAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get event_viewAll;

  /// No description provided for @event_meetingPointLabel.
  ///
  /// In es, this message translates to:
  /// **'Punto de encuentro'**
  String get event_meetingPointLabel;

  /// No description provided for @event_routeLabel.
  ///
  /// In es, this message translates to:
  /// **'Ruta'**
  String get event_routeLabel;

  /// No description provided for @event_aboutEvent.
  ///
  /// In es, this message translates to:
  /// **'Sobre el evento'**
  String get event_aboutEvent;

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

  /// No description provided for @event_alreadyRegistered.
  ///
  /// In es, this message translates to:
  /// **'Ya estás inscrito en este evento'**
  String get event_alreadyRegistered;

  /// No description provided for @event_eventFinished.
  ///
  /// In es, this message translates to:
  /// **'Finalizado'**
  String get event_eventFinished;

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

  /// No description provided for @event_cancelledDescription.
  ///
  /// In es, this message translates to:
  /// **'Cancelaste tu inscripción.'**
  String get event_cancelledDescription;

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

  /// No description provided for @event_participantsSummary.
  ///
  /// In es, this message translates to:
  /// **'{count} personas inscritas · {slots} cupos disponibles'**
  String event_participantsSummary(int count, int slots);

  /// No description provided for @event_participantsSummaryNoSlots.
  ///
  /// In es, this message translates to:
  /// **'{count} personas inscritas'**
  String event_participantsSummaryNoSlots(int count);

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

  /// No description provided for @event_form_difficulty_description.
  ///
  /// In es, this message translates to:
  /// **'{level, select, 1{Fácil — ideal para principiantes y rodadas familiares} 2{Moderado — experiencia básica en ruta recomendada} 3{Intermedio — requiere experiencia en rutas largas} 4{Difícil — habilidades avanzadas necesarias} 5{Extrema — solo para riders expertos} other{Selecciona el nivel de dificultad}}'**
  String event_form_difficulty_description(String level);

  /// No description provided for @event_form_difficulty_section_title.
  ///
  /// In es, this message translates to:
  /// **'DIFICULTAD'**
  String get event_form_difficulty_section_title;

  /// No description provided for @event_form_difficulty_level_label.
  ///
  /// In es, this message translates to:
  /// **'Nivel de dificultad'**
  String get event_form_difficulty_level_label;

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

  /// No description provided for @event_invalidPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio inválido'**
  String get event_invalidPrice;

  /// No description provided for @map_riderTelemetry.
  ///
  /// In es, this message translates to:
  /// **'Rider telemetry'**
  String get map_riderTelemetry;

  /// No description provided for @map_speed.
  ///
  /// In es, this message translates to:
  /// **'Velocidad'**
  String get map_speed;

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

  /// No description provided for @map_endRideConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Finalizar rodada?'**
  String get map_endRideConfirmTitle;

  /// No description provided for @map_endRideConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Se cerrará el seguimiento en vivo para todos los participantes. Esta acción no se puede deshacer.'**
  String get map_endRideConfirmMessage;

  /// No description provided for @map_endRideConfirmButton.
  ///
  /// In es, this message translates to:
  /// **'Sí, finalizar'**
  String get map_endRideConfirmButton;

  /// No description provided for @map_sosAlertTitle.
  ///
  /// In es, this message translates to:
  /// **'Alerta SOS activa'**
  String get map_sosAlertTitle;

  /// No description provided for @map_sosAlertMessage.
  ///
  /// In es, this message translates to:
  /// **'Has enviado una alerta de emergencia. Los demás participantes verán tu ubicación y sabrán que necesitas ayuda.'**
  String get map_sosAlertMessage;

  /// No description provided for @map_sosDismiss.
  ///
  /// In es, this message translates to:
  /// **'Cancelar alerta'**
  String get map_sosDismiss;

  /// No description provided for @map_sosConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Enviar SOS?'**
  String get map_sosConfirmTitle;

  /// No description provided for @map_sosConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'Esto notificará a todos los participantes de la rodada sobre tu emergencia y compartirá tu ubicación en tiempo real.'**
  String get map_sosConfirmMessage;

  /// No description provided for @map_sosSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar SOS'**
  String get map_sosSend;

  /// No description provided for @map_participantsTitle.
  ///
  /// In es, this message translates to:
  /// **'Participantes'**
  String get map_participantsTitle;

  /// No description provided for @map_activeRiders.
  ///
  /// In es, this message translates to:
  /// **'en rodada'**
  String get map_activeRiders;

  /// No description provided for @map_noActiveRidersMessage.
  ///
  /// In es, this message translates to:
  /// **'No hay riders activos en este momento'**
  String get map_noActiveRidersMessage;

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

  /// No description provided for @maintenance_maintenanceDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento eliminado correctamente'**
  String get maintenance_maintenanceDeletedSuccessfully;

  /// No description provided for @maintenance_maintenanceNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas / Observaciones'**
  String get maintenance_maintenanceNotes;

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

  /// No description provided for @maintenance_routine.
  ///
  /// In es, this message translates to:
  /// **'Rutina'**
  String get maintenance_routine;

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

  /// No description provided for @maintenance_km.
  ///
  /// In es, this message translates to:
  /// **'km'**
  String get maintenance_km;

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
  /// **'Ver historial de mantenimientos'**
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

  /// No description provided for @maintenance_vehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get maintenance_vehicle;

  /// No description provided for @maintenance_next.
  ///
  /// In es, this message translates to:
  /// **'Próximo'**
  String get maintenance_next;

  /// No description provided for @maintenance_done.
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get maintenance_done;

  /// No description provided for @maintenance_calculateRemainingDistance.
  ///
  /// In es, this message translates to:
  /// **'Calcular distancia restante'**
  String get maintenance_calculateRemainingDistance;

  /// No description provided for @maintenance_maintenanceDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Servicio'**
  String get maintenance_maintenanceDateLabel;

  /// No description provided for @maintenance_sectionDetails.
  ///
  /// In es, this message translates to:
  /// **'DETALLES DEL SERVICIO'**
  String get maintenance_sectionDetails;

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

  /// No description provided for @vehicle_addShort.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get vehicle_addShort;

  /// No description provided for @vehicle_specBrand.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get vehicle_specBrand;

  /// No description provided for @vehicle_specModel.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get vehicle_specModel;

  /// No description provided for @vehicle_specYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get vehicle_specYear;

  /// No description provided for @vehicle_specPurchaseDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de compra'**
  String get vehicle_specPurchaseDate;

  /// No description provided for @vehicle_identification.
  ///
  /// In es, this message translates to:
  /// **'Identificación del vehículo'**
  String get vehicle_identification;

  /// No description provided for @vehicle_specs.
  ///
  /// In es, this message translates to:
  /// **'Especificaciones'**
  String get vehicle_specs;

  /// No description provided for @vehicle_plate.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get vehicle_plate;

  /// No description provided for @vehicle_vinLabel.
  ///
  /// In es, this message translates to:
  /// **'VIN / No. de Serie'**
  String get vehicle_vinLabel;

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

  /// No description provided for @vehicle_archiveVehicle.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get vehicle_archiveVehicle;

  /// No description provided for @vehicle_unarchiveVehicle.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get vehicle_unarchiveVehicle;

  /// No description provided for @vehicle_archiveVehicleConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Archivar vehículo'**
  String get vehicle_archiveVehicleConfirmTitle;

  /// No description provided for @vehicle_archiveVehicleConfirmContent.
  ///
  /// In es, this message translates to:
  /// **'«{vehicleName}» pasará a la sección de archivados. Podrás restaurarlo cuando quieras.'**
  String vehicle_archiveVehicleConfirmContent(String vehicleName);

  /// No description provided for @vehicle_vehicleArchived.
  ///
  /// In es, this message translates to:
  /// **'Vehículo archivado'**
  String get vehicle_vehicleArchived;

  /// No description provided for @vehicle_vehicleRestored.
  ///
  /// In es, this message translates to:
  /// **'Vehículo restaurado'**
  String get vehicle_vehicleRestored;

  /// No description provided for @vehicle_archivedSection.
  ///
  /// In es, this message translates to:
  /// **'ARCHIVADOS'**
  String get vehicle_archivedSection;

  /// No description provided for @vehicle_setMainVehicle.
  ///
  /// In es, this message translates to:
  /// **'Marcar como principal'**
  String get vehicle_setMainVehicle;

  /// No description provided for @vehicle_archiveConfirmButton.
  ///
  /// In es, this message translates to:
  /// **'Archivar'**
  String get vehicle_archiveConfirmButton;

  /// No description provided for @vehicle_deleteVehicleConfirmContent.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar «{vehicleName}»?\n\nEsta acción eliminará todos los mantenimientos asociados a este vehículo y no se podrá deshacer.'**
  String vehicle_deleteVehicleConfirmContent(String vehicleName);

  /// No description provided for @vehicle_vehicleDeleted.
  ///
  /// In es, this message translates to:
  /// **'Vehículo eliminado exitosamente'**
  String get vehicle_vehicleDeleted;

  /// No description provided for @vehicle_noVehicles.
  ///
  /// In es, this message translates to:
  /// **'No tienes vehículos registrados'**
  String get vehicle_noVehicles;

  /// No description provided for @vehicle_mainVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo principal'**
  String get vehicle_mainVehicle;

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

  /// No description provided for @vehicle_vehicleName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del vehículo'**
  String get vehicle_vehicleName;

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

  /// No description provided for @vehicle_nameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre es requerido'**
  String get vehicle_nameRequired;

  /// No description provided for @vehicle_brandRequired.
  ///
  /// In es, this message translates to:
  /// **'La marca es requerida'**
  String get vehicle_brandRequired;

  /// No description provided for @vehicle_modelRequired.
  ///
  /// In es, this message translates to:
  /// **'El modelo es requerido'**
  String get vehicle_modelRequired;

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

  /// No description provided for @profile_title.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get profile_title;

  /// No description provided for @profile_mainVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo principal'**
  String get profile_mainVehicle;

  /// No description provided for @profile_noVehicle.
  ///
  /// In es, this message translates to:
  /// **'Sin vehículos'**
  String get profile_noVehicle;

  /// No description provided for @profile_loadingError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu perfil'**
  String get profile_loadingError;

  /// No description provided for @profile_editTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profile_editTitle;

  /// No description provided for @profile_editSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get profile_editSave;

  /// No description provided for @profile_fieldFullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get profile_fieldFullName;

  /// No description provided for @profile_fieldPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get profile_fieldPhone;

  /// No description provided for @profile_fieldCity.
  ///
  /// In es, this message translates to:
  /// **'Ciudad de residencia'**
  String get profile_fieldCity;

  /// No description provided for @profile_fieldBloodType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de sangre'**
  String get profile_fieldBloodType;

  /// No description provided for @profile_fieldEmergencyContact.
  ///
  /// In es, this message translates to:
  /// **'Contacto de emergencia'**
  String get profile_fieldEmergencyContact;

  /// No description provided for @profile_fieldEmergencyPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono de emergencia'**
  String get profile_fieldEmergencyPhone;

  /// No description provided for @profile_sectionPersonal.
  ///
  /// In es, this message translates to:
  /// **'Información personal'**
  String get profile_sectionPersonal;

  /// No description provided for @profile_sectionEmergency.
  ///
  /// In es, this message translates to:
  /// **'Contacto de emergencia'**
  String get profile_sectionEmergency;

  /// No description provided for @profile_editInfo.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profile_editInfo;

  /// No description provided for @profile_statsEvents.
  ///
  /// In es, this message translates to:
  /// **'Rodadas'**
  String get profile_statsEvents;

  /// No description provided for @profile_statsKm.
  ///
  /// In es, this message translates to:
  /// **'Km'**
  String get profile_statsKm;

  /// No description provided for @profile_statsFollowers.
  ///
  /// In es, this message translates to:
  /// **'Seguidores'**
  String get profile_statsFollowers;

  /// No description provided for @profile_settings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get profile_settings;

  /// No description provided for @profile_registrations.
  ///
  /// In es, this message translates to:
  /// **'Mis inscripciones'**
  String get profile_registrations;

  /// No description provided for @profile_maintenances.
  ///
  /// In es, this message translates to:
  /// **'Mantenimientos'**
  String get profile_maintenances;

  /// No description provided for @profile_analyticsOptOutLabel.
  ///
  /// In es, this message translates to:
  /// **'Compartir datos de uso anónimos'**
  String get profile_analyticsOptOutLabel;

  /// No description provided for @profile_analyticsOptOutSaveError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar tu preferencia. Inténtalo de nuevo.'**
  String get profile_analyticsOptOutSaveError;

  /// No description provided for @registration_registrationPageTitle.
  ///
  /// In es, this message translates to:
  /// **'Inscripción al Evento'**
  String get registration_registrationPageTitle;

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

  /// No description provided for @registration_emergencyContact.
  ///
  /// In es, this message translates to:
  /// **'Contacto de emergencia'**
  String get registration_emergencyContact;

  /// No description provided for @registration_fullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get registration_fullName;

  /// No description provided for @registration_fullNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Juan Carlos Pérez Rodríguez'**
  String get registration_fullNameHint;

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

  /// No description provided for @registration_fullNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre completo es requerido'**
  String get registration_fullNameRequired;

  /// No description provided for @registration_identificationHint.
  ///
  /// In es, this message translates to:
  /// **'Documento de identidad'**
  String get registration_identificationHint;

  /// No description provided for @registration_birthDateHint.
  ///
  /// In es, this message translates to:
  /// **'mm/dd/yyyy'**
  String get registration_birthDateHint;

  /// No description provided for @registration_birthDateRequired.
  ///
  /// In es, this message translates to:
  /// **'La fecha de nacimiento es requerida'**
  String get registration_birthDateRequired;

  /// No description provided for @registration_residenceCitySelectFromList.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una opción válida de la lista'**
  String get registration_residenceCitySelectFromList;

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

  /// No description provided for @registration_selectVehicleToPreload.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un vehículo'**
  String get registration_selectVehicleToPreload;

  /// No description provided for @registration_selectVehiclePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu vehículo'**
  String get registration_selectVehiclePlaceholder;

  /// No description provided for @registration_changeVehicle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get registration_changeVehicle;

  /// No description provided for @registration_vehicleEmptyStateSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Registra tu moto para inscribirte en el evento.'**
  String get registration_vehicleEmptyStateSubtitle;

  /// No description provided for @registration_vehicleBrandNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'La marca seleccionada no está permitida para este evento. Las marcas pemitidas son'**
  String get registration_vehicleBrandNotAllowed;

  /// No description provided for @registration_vehicleEmptyStateTitle.
  ///
  /// In es, this message translates to:
  /// **'No tienes vehículos disponibles para esta inscripción.'**
  String get registration_vehicleEmptyStateTitle;

  /// No description provided for @registration_createVehicleCta.
  ///
  /// In es, this message translates to:
  /// **'Crear vehículo'**
  String get registration_createVehicleCta;

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

  /// No description provided for @registration_finishRegistration.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Inscripción'**
  String get registration_finishRegistration;

  /// No description provided for @registration_nextStep.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get registration_nextStep;

  /// No description provided for @registration_previousStep.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get registration_previousStep;

  /// No description provided for @registration_stepPersonalTitle.
  ///
  /// In es, this message translates to:
  /// **'Información Personal'**
  String get registration_stepPersonalTitle;

  /// No description provided for @registration_stepPersonalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Datos básicos del piloto'**
  String get registration_stepPersonalSubtitle;

  /// No description provided for @registration_stepMedicalTitle.
  ///
  /// In es, this message translates to:
  /// **'Información Médica'**
  String get registration_stepMedicalTitle;

  /// No description provided for @registration_stepMedicalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de salud para el evento'**
  String get registration_stepMedicalSubtitle;

  /// No description provided for @registration_stepEmergencyTitle.
  ///
  /// In es, this message translates to:
  /// **'Contacto de Emergencia'**
  String get registration_stepEmergencyTitle;

  /// No description provided for @registration_stepEmergencySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Persona a contactar en caso de accidente'**
  String get registration_stepEmergencySubtitle;

  /// No description provided for @registration_stepVehicleTitle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo de Inscripción'**
  String get registration_stepVehicleTitle;

  /// No description provided for @registration_stepVehicleSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Moto con la que participarás en el evento'**
  String get registration_stepVehicleSubtitle;

  /// No description provided for @registration_bloodTypeSelectHint.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu grupo'**
  String get registration_bloodTypeSelectHint;

  /// Checkbox label to opt-in to persist rider info to user profile after registering.
  ///
  /// In es, this message translates to:
  /// **'Guardar mis datos para futuras inscripciones'**
  String get registration_saveToProfile;

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

  /// No description provided for @form_phoneRequired.
  ///
  /// In es, this message translates to:
  /// **'El celular es requerido'**
  String get form_phoneRequired;

  /// No description provided for @form_phoneOnlyDigits.
  ///
  /// In es, this message translates to:
  /// **'Solo se permiten dígitos'**
  String get form_phoneOnlyDigits;

  /// No description provided for @form_phoneInvalidLength.
  ///
  /// In es, this message translates to:
  /// **'El celular debe tener 10 dígitos'**
  String get form_phoneInvalidLength;

  /// No description provided for @form_emailRequired.
  ///
  /// In es, this message translates to:
  /// **'El correo electrónico es requerido'**
  String get form_emailRequired;

  /// No description provided for @form_emailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico inválido'**
  String get form_emailInvalid;

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
  /// **'El vehículo es requerido'**
  String get registration_vehicleBrandRequired;

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

  /// No description provided for @registration_viewDetail.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle'**
  String get registration_viewDetail;

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

  /// No description provided for @registration_requestDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle de solicitud'**
  String get registration_requestDetailsTitle;

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

  /// No description provided for @registration_emergencyContactTitle.
  ///
  /// In es, this message translates to:
  /// **'Contacto de Emergencia'**
  String get registration_emergencyContactTitle;

  /// No description provided for @registration_participationData.
  ///
  /// In es, this message translates to:
  /// **'Datos de Participación'**
  String get registration_participationData;

  /// No description provided for @registration_rowName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get registration_rowName;

  /// No description provided for @registration_rowIdentification.
  ///
  /// In es, this message translates to:
  /// **'Identificación'**
  String get registration_rowIdentification;

  /// No description provided for @registration_rowBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get registration_rowBirthDate;

  /// No description provided for @registration_rowPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get registration_rowPhone;

  /// No description provided for @registration_rowEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get registration_rowEmail;

  /// No description provided for @registration_rowCity.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get registration_rowCity;

  /// No description provided for @registration_rowEps.
  ///
  /// In es, this message translates to:
  /// **'EPS'**
  String get registration_rowEps;

  /// No description provided for @registration_rowMedicalInsurance.
  ///
  /// In es, this message translates to:
  /// **'Seguro médico'**
  String get registration_rowMedicalInsurance;

  /// No description provided for @registration_rowBloodType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de sangre'**
  String get registration_rowBloodType;

  /// No description provided for @registration_rowContactName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del contacto'**
  String get registration_rowContactName;

  /// No description provided for @registration_rowVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get registration_rowVehicle;

  /// No description provided for @registration_rowParticipationType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de participación'**
  String get registration_rowParticipationType;

  /// No description provided for @registration_rowCompanions.
  ///
  /// In es, this message translates to:
  /// **'Acompañantes'**
  String get registration_rowCompanions;

  /// No description provided for @registration_participationRiderPrincipal.
  ///
  /// In es, this message translates to:
  /// **'Rider principal'**
  String get registration_participationRiderPrincipal;

  /// No description provided for @registration_requestEdit.
  ///
  /// In es, this message translates to:
  /// **'Solicitar edición'**
  String get registration_requestEdit;

  /// No description provided for @registration_editRegistrationCta.
  ///
  /// In es, this message translates to:
  /// **'Editar inscripción'**
  String get registration_editRegistrationCta;

  /// No description provided for @registration_pendingBannerText.
  ///
  /// In es, this message translates to:
  /// **'Tu inscripción está pendiente de revisión'**
  String get registration_pendingBannerText;

  /// No description provided for @registration_rejectedBannerText.
  ///
  /// In es, this message translates to:
  /// **'Tu inscripción fue rechazada'**
  String get registration_rejectedBannerText;

  /// No description provided for @registration_readyForEditBannerText.
  ///
  /// In es, this message translates to:
  /// **'Puedes editar tu inscripción'**
  String get registration_readyForEditBannerText;

  /// No description provided for @registration_approvedBannerText.
  ///
  /// In es, this message translates to:
  /// **'Tu inscripción fue aprobada'**
  String get registration_approvedBannerText;

  /// No description provided for @registration_cancelledBannerText.
  ///
  /// In es, this message translates to:
  /// **'Cancelaste tu inscripción'**
  String get registration_cancelledBannerText;

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

  /// No description provided for @splash_forceUpdateTitle.
  ///
  /// In es, this message translates to:
  /// **'Actualización requerida'**
  String get splash_forceUpdateTitle;

  /// No description provided for @splash_forceUpdateMessage.
  ///
  /// In es, this message translates to:
  /// **'Hay una nueva versión de la app disponible. Debes actualizar para continuar.'**
  String get splash_forceUpdateMessage;

  /// No description provided for @splash_forceUpdateButton.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get splash_forceUpdateButton;

  /// No description provided for @home_greeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, Rider'**
  String get home_greeting;

  /// No description provided for @home_viewDetails.
  ///
  /// In es, this message translates to:
  /// **'Ver detalles'**
  String get home_viewDetails;

  /// No description provided for @appfields_mileageRequired.
  ///
  /// In es, this message translates to:
  /// **'El kilometraje es requerido'**
  String get appfields_mileageRequired;

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

  /// No description provided for @registration_requestEditConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitar edición'**
  String get registration_requestEditConfirmTitle;

  /// No description provided for @registration_requestEditConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Pedirle a {name} que edite su inscripción?'**
  String registration_requestEditConfirmMessage(Object name);

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

  /// No description provided for @event_noResultsFiltered.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos con estos filtros'**
  String get event_noResultsFiltered;

  /// No description provided for @rider_profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil del motorista'**
  String get rider_profileTitle;

  /// No description provided for @rider_follow.
  ///
  /// In es, this message translates to:
  /// **'Seguir'**
  String get rider_follow;

  /// No description provided for @rider_statsEvents.
  ///
  /// In es, this message translates to:
  /// **'Rodadas'**
  String get rider_statsEvents;

  /// No description provided for @rider_statsFollowers.
  ///
  /// In es, this message translates to:
  /// **'Seguidores'**
  String get rider_statsFollowers;

  /// No description provided for @rider_statsFollowing.
  ///
  /// In es, this message translates to:
  /// **'Siguiendo'**
  String get rider_statsFollowing;

  /// No description provided for @auth_welcome_title.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get auth_welcome_title;

  /// No description provided for @auth_welcome_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para continuar'**
  String get auth_welcome_subtitle;

  /// No description provided for @auth_email_label.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get auth_email_label;

  /// No description provided for @auth_email_placeholder.
  ///
  /// In es, this message translates to:
  /// **'tu@correo.com'**
  String get auth_email_placeholder;

  /// No description provided for @auth_password_label.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get auth_password_label;

  /// No description provided for @auth_password_placeholder.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get auth_password_placeholder;

  /// No description provided for @auth_forgot_password.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get auth_forgot_password;

  /// No description provided for @auth_sign_in.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get auth_sign_in;

  /// No description provided for @auth_continue_with_google.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get auth_continue_with_google;

  /// No description provided for @auth_no_account.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get auth_no_account;

  /// No description provided for @auth_register_link.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get auth_register_link;

  /// No description provided for @auth_create_account_title.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get auth_create_account_title;

  /// No description provided for @auth_join_community.
  ///
  /// In es, this message translates to:
  /// **'Únete a la comunidad'**
  String get auth_join_community;

  /// No description provided for @auth_full_name_label.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get auth_full_name_label;

  /// No description provided for @auth_confirm_password_label.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get auth_confirm_password_label;

  /// No description provided for @auth_terms_text.
  ///
  /// In es, this message translates to:
  /// **'Acepto los Términos de uso y la Política de privacidad de Rideglory'**
  String get auth_terms_text;

  /// No description provided for @auth_create_account_btn.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get auth_create_account_btn;

  /// No description provided for @auth_already_have_account.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get auth_already_have_account;

  /// No description provided for @auth_sign_in_link.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get auth_sign_in_link;

  /// No description provided for @auth_recovery_heading.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get auth_recovery_heading;

  /// No description provided for @auth_recovery_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo y te enviaremos un enlace para restablecerla.'**
  String get auth_recovery_subtitle;

  /// No description provided for @auth_recovery_send.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get auth_recovery_send;

  /// No description provided for @auth_recovery_back.
  ///
  /// In es, this message translates to:
  /// **'← Volver al inicio de sesión'**
  String get auth_recovery_back;

  /// No description provided for @auth_recovery_sent_title.
  ///
  /// In es, this message translates to:
  /// **'Correo enviado'**
  String get auth_recovery_sent_title;

  /// No description provided for @auth_recovery_sent_body.
  ///
  /// In es, this message translates to:
  /// **'Revisamos tu correo en {email}. El enlace expira en 15 minutos.'**
  String auth_recovery_sent_body(String email);

  /// No description provided for @auth_recovery_back_home.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get auth_recovery_back_home;

  /// No description provided for @auth_recovery_resend.
  ///
  /// In es, this message translates to:
  /// **'No recibí el correo — reenviar'**
  String get auth_recovery_resend;

  /// No description provided for @home_sectionGarage.
  ///
  /// In es, this message translates to:
  /// **'Mi garaje'**
  String get home_sectionGarage;

  /// No description provided for @home_sectionEvents.
  ///
  /// In es, this message translates to:
  /// **'Próximas rodadas'**
  String get home_sectionEvents;

  /// No description provided for @home_viewAllLink.
  ///
  /// In es, this message translates to:
  /// **'Ver todas'**
  String get home_viewAllLink;

  /// No description provided for @home_viewCatalog.
  ///
  /// In es, this message translates to:
  /// **'Ver catálogo completo de eventos'**
  String get home_viewCatalog;

  /// No description provided for @home_emptyGarageTitle.
  ///
  /// In es, this message translates to:
  /// **'Agrega tu primera moto'**
  String get home_emptyGarageTitle;

  /// No description provided for @home_emptyGarageSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Lleva el control de tu garaje y mantenimientos'**
  String get home_emptyGarageSubtitle;

  /// No description provided for @home_emptyGarageCta.
  ///
  /// In es, this message translates to:
  /// **'Agregar moto'**
  String get home_emptyGarageCta;

  /// No description provided for @home_emptyEventsTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin rodadas próximas'**
  String get home_emptyEventsTitle;

  /// No description provided for @home_emptyEventsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Explora los eventos disponibles y únete a la comunidad'**
  String get home_emptyEventsSubtitle;

  /// No description provided for @home_emptyEventsCta.
  ///
  /// In es, this message translates to:
  /// **'Ver eventos'**
  String get home_emptyEventsCta;

  /// No description provided for @event_form_max_participants_label.
  ///
  /// In es, this message translates to:
  /// **'Participantes'**
  String get event_form_max_participants_label;

  /// No description provided for @event_form_publish_action.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get event_form_publish_action;

  /// No description provided for @event_form_optional_badge.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get event_form_optional_badge;

  /// No description provided for @event_form_max_participants_section_title.
  ///
  /// In es, this message translates to:
  /// **'CUPO MÁXIMO'**
  String get event_form_max_participants_section_title;

  /// No description provided for @event_form_max_participants_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Máximo de inscritos'**
  String get event_form_max_participants_subtitle;

  /// No description provided for @event_form_max_participants_hint.
  ///
  /// In es, this message translates to:
  /// **'Una vez lleno el cupo, el evento aparece como \'Completo\' automáticamente.'**
  String get event_form_max_participants_hint;

  /// No description provided for @event_form_price_section_title.
  ///
  /// In es, this message translates to:
  /// **'PRECIO POR PERSONA'**
  String get event_form_price_section_title;

  /// No description provided for @event_form_price_free_hint.
  ///
  /// In es, this message translates to:
  /// **'Usa el stepper o toca el valor para editarlo'**
  String get event_form_price_free_hint;

  /// No description provided for @vehicle_doc_soat_label.
  ///
  /// In es, this message translates to:
  /// **'SOAT'**
  String get vehicle_doc_soat_label;

  /// No description provided for @vehicle_doc_techreview_label.
  ///
  /// In es, this message translates to:
  /// **'Técnico-mecánica'**
  String get vehicle_doc_techreview_label;

  /// No description provided for @vehicle_form_brand_label.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get vehicle_form_brand_label;

  /// No description provided for @vehicle_form_model_label.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get vehicle_form_model_label;

  /// No description provided for @vehicle_form_year_label.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get vehicle_form_year_label;

  /// No description provided for @vehicle_form_color_label.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get vehicle_form_color_label;

  /// No description provided for @vehicle_form_plate_label.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get vehicle_form_plate_label;

  /// No description provided for @vehicle_form_km_label.
  ///
  /// In es, this message translates to:
  /// **'Kilometraje actual'**
  String get vehicle_form_km_label;

  /// No description provided for @vehicle_form_cover_title.
  ///
  /// In es, this message translates to:
  /// **'Agregar foto de portada'**
  String get vehicle_form_cover_title;

  /// No description provided for @vehicle_form_cover_subtitle.
  ///
  /// In es, this message translates to:
  /// **'JPG, PNG · Máx. 10MB'**
  String get vehicle_form_cover_subtitle;

  /// No description provided for @vehicle_form_upload_btn.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get vehicle_form_upload_btn;

  /// No description provided for @vehicle_form_take_photo_btn.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get vehicle_form_take_photo_btn;

  /// No description provided for @vehicle_form_scan_title.
  ///
  /// In es, this message translates to:
  /// **'Escanear tarjeta de propiedad'**
  String get vehicle_form_scan_title;

  /// No description provided for @vehicle_form_scan_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Autocompleta marca, modelo, año, placa y VIN automáticamente'**
  String get vehicle_form_scan_subtitle;

  /// No description provided for @vehicle_form_info_section.
  ///
  /// In es, this message translates to:
  /// **'INFORMACIÓN BÁSICA'**
  String get vehicle_form_info_section;

  /// No description provided for @vehicle_form_id_section.
  ///
  /// In es, this message translates to:
  /// **'IDENTIFICACIÓN'**
  String get vehicle_form_id_section;

  /// No description provided for @vehicle_form_color_hint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Azul, Negro mate'**
  String get vehicle_form_color_hint;

  /// No description provided for @vehicle_form_docs_section.
  ///
  /// In es, this message translates to:
  /// **'DOCUMENTOS'**
  String get vehicle_form_docs_section;

  /// No description provided for @vehicle_form_soat_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Seguro obligatorio de accidentes'**
  String get vehicle_form_soat_subtitle;

  /// No description provided for @vehicle_form_techreview_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Rev. técnica del vehículo'**
  String get vehicle_form_techreview_subtitle;

  /// No description provided for @vehicle_form_add_doc_title.
  ///
  /// In es, this message translates to:
  /// **'Agregar otro documento'**
  String get vehicle_form_add_doc_title;

  /// No description provided for @vehicle_form_add_doc_subtitle.
  ///
  /// In es, this message translates to:
  /// **'PDF, JPG, PNG · Máx. 5 MB'**
  String get vehicle_form_add_doc_subtitle;

  /// No description provided for @vehicle_form_docs_max_hint.
  ///
  /// In es, this message translates to:
  /// **'Máximo 3 documentos por vehículo'**
  String get vehicle_form_docs_max_hint;

  /// No description provided for @vehicle_form_save.
  ///
  /// In es, this message translates to:
  /// **'Guardar moto'**
  String get vehicle_form_save;

  /// No description provided for @vehicle_form_delete_vehicle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar vehículo'**
  String get vehicle_form_delete_vehicle;

  /// No description provided for @vehicle_form_placa_required_badge.
  ///
  /// In es, this message translates to:
  /// **'Obligatorio'**
  String get vehicle_form_placa_required_badge;

  /// No description provided for @vehicle_form_vin_optional_label.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get vehicle_form_vin_optional_label;

  /// No description provided for @vehicle_form_specs_section.
  ///
  /// In es, this message translates to:
  /// **'ESPECIFICACIONES'**
  String get vehicle_form_specs_section;

  /// No description provided for @vehicle_form_specs_engine_label.
  ///
  /// In es, this message translates to:
  /// **'Motor'**
  String get vehicle_form_specs_engine_label;

  /// No description provided for @vehicle_form_specs_horsepower_label.
  ///
  /// In es, this message translates to:
  /// **'Potencia'**
  String get vehicle_form_specs_horsepower_label;

  /// No description provided for @vehicle_form_specs_torque_label.
  ///
  /// In es, this message translates to:
  /// **'Torque'**
  String get vehicle_form_specs_torque_label;

  /// No description provided for @vehicle_form_specs_weight_label.
  ///
  /// In es, this message translates to:
  /// **'Peso'**
  String get vehicle_form_specs_weight_label;

  /// No description provided for @vehicle_form_specs_engine_hint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 689cc · Paralelo 2 cil.'**
  String get vehicle_form_specs_engine_hint;

  /// No description provided for @vehicle_form_specs_horsepower_hint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 73 hp'**
  String get vehicle_form_specs_horsepower_hint;

  /// No description provided for @vehicle_form_specs_torque_hint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 68 Nm'**
  String get vehicle_form_specs_torque_hint;

  /// No description provided for @vehicle_form_specs_weight_hint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 179 kg'**
  String get vehicle_form_specs_weight_hint;

  /// No description provided for @maintenance_form_new_title.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Mantenimiento'**
  String get maintenance_form_new_title;

  /// No description provided for @maintenance_form_step_select_label.
  ///
  /// In es, this message translates to:
  /// **'Paso 1 de 2'**
  String get maintenance_form_step_select_label;

  /// No description provided for @maintenance_form_step_select.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el tipo de mantenimiento'**
  String get maintenance_form_step_select;

  /// No description provided for @maintenance_form_step_continue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get maintenance_form_step_continue;

  /// No description provided for @maintenance_form_tab_done.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get maintenance_form_tab_done;

  /// No description provided for @maintenance_form_tab_scheduled.
  ///
  /// In es, this message translates to:
  /// **'Programado'**
  String get maintenance_form_tab_scheduled;

  /// No description provided for @maintenance_form_save_done.
  ///
  /// In es, this message translates to:
  /// **'Guardar mantenimiento'**
  String get maintenance_form_save_done;

  /// No description provided for @maintenance_form_discard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get maintenance_form_discard;

  /// No description provided for @maintenance_form_estado_section.
  ///
  /// In es, this message translates to:
  /// **'ESTADO'**
  String get maintenance_form_estado_section;

  /// No description provided for @maintenance_form_context_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Tipo de mantenimiento seleccionado'**
  String get maintenance_form_context_subtitle;

  /// No description provided for @maintenance_form_km_label.
  ///
  /// In es, this message translates to:
  /// **'Kilometraje al momento del servicio'**
  String get maintenance_form_km_label;

  /// No description provided for @maintenance_form_cost_taller_section.
  ///
  /// In es, this message translates to:
  /// **'COSTO Y TALLER'**
  String get maintenance_form_cost_taller_section;

  /// No description provided for @maintenance_form_taller_label.
  ///
  /// In es, this message translates to:
  /// **'Taller / Mecánico'**
  String get maintenance_form_taller_label;

  /// No description provided for @maintenance_form_notes_section.
  ///
  /// In es, this message translates to:
  /// **'NOTAS'**
  String get maintenance_form_notes_section;

  /// No description provided for @maintenance_form_date_scheduled_label.
  ///
  /// In es, this message translates to:
  /// **'Fecha programada'**
  String get maintenance_form_date_scheduled_label;

  /// No description provided for @maintenance_scheduled_requires_date_or_km.
  ///
  /// In es, this message translates to:
  /// **'Debes ingresar al menos la fecha o los km del próximo mantenimiento'**
  String get maintenance_scheduled_requires_date_or_km;

  /// No description provided for @maintenance_prox_service_in.
  ///
  /// In es, this message translates to:
  /// **'Próximo servicio en'**
  String get maintenance_prox_service_in;

  /// No description provided for @maintenance_filter_type_label.
  ///
  /// In es, this message translates to:
  /// **'Tipo de mantenimiento'**
  String get maintenance_filter_type_label;

  /// No description provided for @maintenance_filter_status_label.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get maintenance_filter_status_label;

  /// No description provided for @maintenance_filter_status_all.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get maintenance_filter_status_all;

  /// No description provided for @maintenance_filter_status_overdue.
  ///
  /// In es, this message translates to:
  /// **'Atrasado'**
  String get maintenance_filter_status_overdue;

  /// No description provided for @maintenance_filter_status_upcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximo'**
  String get maintenance_filter_status_upcoming;

  /// No description provided for @maintenance_filter_status_on_track.
  ///
  /// In es, this message translates to:
  /// **'Al día'**
  String get maintenance_filter_status_on_track;

  /// No description provided for @maintenance_filter_date_range_label.
  ///
  /// In es, this message translates to:
  /// **'Rango de fecha'**
  String get maintenance_filter_date_range_label;

  /// No description provided for @maintenance_filter_date_this_month.
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get maintenance_filter_date_this_month;

  /// No description provided for @maintenance_filter_date_last_3_months.
  ///
  /// In es, this message translates to:
  /// **'Últimos 3 meses'**
  String get maintenance_filter_date_last_3_months;

  /// No description provided for @maintenance_filter_date_last_year.
  ///
  /// In es, this message translates to:
  /// **'Último año'**
  String get maintenance_filter_date_last_year;

  /// No description provided for @maintenance_filter_date_custom.
  ///
  /// In es, this message translates to:
  /// **'Personalizado'**
  String get maintenance_filter_date_custom;

  /// No description provided for @maintenance_filter_clear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get maintenance_filter_clear;

  /// No description provided for @maintenance_filter_clear_all.
  ///
  /// In es, this message translates to:
  /// **'Limpiar todo'**
  String get maintenance_filter_clear_all;

  /// No description provided for @filter_title.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get filter_title;

  /// No description provided for @filter_clearAll.
  ///
  /// In es, this message translates to:
  /// **'Limpiar todo'**
  String get filter_clearAll;

  /// No description provided for @filter_clear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get filter_clear;

  /// No description provided for @filter_apply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get filter_apply;

  /// No description provided for @maintenance_legend_warning.
  ///
  /// In es, this message translates to:
  /// **'Próximo'**
  String get maintenance_legend_warning;

  /// No description provided for @maintenance_status_overdue.
  ///
  /// In es, this message translates to:
  /// **'atrasado'**
  String get maintenance_status_overdue;

  /// No description provided for @maintenance_km_remaining.
  ///
  /// In es, this message translates to:
  /// **'faltan'**
  String get maintenance_km_remaining;

  /// No description provided for @nav_inicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get nav_inicio;

  /// No description provided for @nav_garaje.
  ///
  /// In es, this message translates to:
  /// **'Garaje'**
  String get nav_garaje;

  /// No description provided for @nav_eventos.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get nav_eventos;

  /// No description provided for @nav_perfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get nav_perfil;

  /// No description provided for @notification_centerTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notification_centerTitle;

  /// No description provided for @notification_markAllRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar todo como leído'**
  String get notification_markAllRead;

  /// No description provided for @notification_emptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin notificaciones'**
  String get notification_emptyTitle;

  /// No description provided for @notification_emptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Aquí aparecerán tus inscripciones aprobadas, recordatorios de eventos y más.'**
  String get notification_emptySubtitle;

  /// No description provided for @notification_sectionUnread.
  ///
  /// In es, this message translates to:
  /// **'NO LEÍDAS'**
  String get notification_sectionUnread;

  /// No description provided for @notification_sectionRead.
  ///
  /// In es, this message translates to:
  /// **'ANTERIORES'**
  String get notification_sectionRead;

  /// No description provided for @registration_statusBadgeApproved.
  ///
  /// In es, this message translates to:
  /// **'Aprobada'**
  String get registration_statusBadgeApproved;

  /// No description provided for @registration_statusBadgePending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get registration_statusBadgePending;

  /// No description provided for @registration_statusBadgeRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazada'**
  String get registration_statusBadgeRejected;

  /// No description provided for @registration_statusBadgeCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get registration_statusBadgeCancelled;

  /// No description provided for @registration_statusBadgeReadyForEdit.
  ///
  /// In es, this message translates to:
  /// **'Para editar'**
  String get registration_statusBadgeReadyForEdit;

  /// No description provided for @event_registrationsTab.
  ///
  /// In es, this message translates to:
  /// **'Inscritos'**
  String get event_registrationsTab;

  /// No description provided for @event_manageAttendeesTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar inscritos'**
  String get event_manageAttendeesTitle;

  /// No description provided for @event_attendee_joinedDaysAgo.
  ///
  /// In es, this message translates to:
  /// **'Se unió hace {days} días'**
  String event_attendee_joinedDaysAgo(int days);

  /// No description provided for @event_attendee_joinedHoursAgo.
  ///
  /// In es, this message translates to:
  /// **'Se unió hace {hours} h'**
  String event_attendee_joinedHoursAgo(int hours);

  /// No description provided for @event_attendee_joinedMinutesAgo.
  ///
  /// In es, this message translates to:
  /// **'Se unió hace {minutes} min'**
  String event_attendee_joinedMinutesAgo(int minutes);

  /// No description provided for @event_attendee_joinedRecently.
  ///
  /// In es, this message translates to:
  /// **'Se unió hace un momento'**
  String get event_attendee_joinedRecently;

  /// No description provided for @sos_banner_subtitle_with_phone.
  ///
  /// In es, this message translates to:
  /// **'Toca para ver acciones'**
  String get sos_banner_subtitle_with_phone;

  /// No description provided for @sos_banner_subtitle_no_phone.
  ///
  /// In es, this message translates to:
  /// **'Sin teléfono registrado'**
  String get sos_banner_subtitle_no_phone;

  /// No description provided for @sos_call_action.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get sos_call_action;

  /// No description provided for @sos_locate_action.
  ///
  /// In es, this message translates to:
  /// **'Localizar'**
  String get sos_locate_action;

  /// No description provided for @sos_locate_sheet_title.
  ///
  /// In es, this message translates to:
  /// **'Localizar a {riderName}'**
  String sos_locate_sheet_title(String riderName);

  /// No description provided for @sos_locate_center_option.
  ///
  /// In es, this message translates to:
  /// **'Centrar en el mapa'**
  String get sos_locate_center_option;

  /// No description provided for @sos_locate_external_option.
  ///
  /// In es, this message translates to:
  /// **'Abrir en Google Maps'**
  String get sos_locate_external_option;

  /// No description provided for @sos_cancel_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'¿Desactivar SOS?'**
  String get sos_cancel_confirm_title;

  /// No description provided for @sos_cancel_confirm_body.
  ///
  /// In es, this message translates to:
  /// **'Se cancelará tu alerta de emergencia y los demás riders dejarán de verla.'**
  String get sos_cancel_confirm_body;

  /// No description provided for @sos_cancel_confirm_action.
  ///
  /// In es, this message translates to:
  /// **'Desactivar SOS'**
  String get sos_cancel_confirm_action;

  /// No description provided for @sos_banner_title.
  ///
  /// In es, this message translates to:
  /// **'{riderName} necesita ayuda'**
  String sos_banner_title(String riderName);

  /// No description provided for @tracking_end_ride.
  ///
  /// In es, this message translates to:
  /// **'Terminar rodada'**
  String get tracking_end_ride;

  /// No description provided for @tracking_end_ride_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'¿Terminar rodada?'**
  String get tracking_end_ride_confirm_title;

  /// No description provided for @tracking_end_ride_confirm_body.
  ///
  /// In es, this message translates to:
  /// **'La pantalla de rastreo se cerrará para todos los riders conectados. Esta acción no se puede deshacer.'**
  String get tracking_end_ride_confirm_body;

  /// No description provided for @tracking_ride_finished.
  ///
  /// In es, this message translates to:
  /// **'¡La rodada ha terminado!'**
  String get tracking_ride_finished;

  /// No description provided for @tracking_ride_finished_body.
  ///
  /// In es, this message translates to:
  /// **'{eventName} ha finalizado exitosamente.'**
  String tracking_ride_finished_body(String eventName);

  /// No description provided for @tracking_back_to_home.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get tracking_back_to_home;

  /// No description provided for @tracking_organizer_badge.
  ///
  /// In es, this message translates to:
  /// **'Organizador'**
  String get tracking_organizer_badge;

  /// No description provided for @tracking_organizer_label.
  ///
  /// In es, this message translates to:
  /// **'Control de rodada'**
  String get tracking_organizer_label;

  /// No description provided for @vehicle_soat_tap_to_add.
  ///
  /// In es, this message translates to:
  /// **'Sin registrar · Agregar →'**
  String get vehicle_soat_tap_to_add;

  /// No description provided for @vehicle_soat_form_title.
  ///
  /// In es, this message translates to:
  /// **'Registrar SOAT'**
  String get vehicle_soat_form_title;

  /// No description provided for @vehicle_soat_policy_number_label.
  ///
  /// In es, this message translates to:
  /// **'Número de póliza'**
  String get vehicle_soat_policy_number_label;

  /// No description provided for @vehicle_soat_policy_number_hint.
  ///
  /// In es, this message translates to:
  /// **'Ej: SOA-123456'**
  String get vehicle_soat_policy_number_hint;

  /// No description provided for @vehicle_soat_insurer_label.
  ///
  /// In es, this message translates to:
  /// **'Aseguradora'**
  String get vehicle_soat_insurer_label;

  /// No description provided for @vehicle_soat_insurer_hint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Sura, Colseguros...'**
  String get vehicle_soat_insurer_hint;

  /// No description provided for @vehicle_soat_start_date_label.
  ///
  /// In es, this message translates to:
  /// **'Fecha de inicio'**
  String get vehicle_soat_start_date_label;

  /// No description provided for @vehicle_soat_start_date_hint.
  ///
  /// In es, this message translates to:
  /// **'dd/mm/aaaa'**
  String get vehicle_soat_start_date_hint;

  /// No description provided for @vehicle_soat_expiry_date_label.
  ///
  /// In es, this message translates to:
  /// **'Fecha de vencimiento'**
  String get vehicle_soat_expiry_date_label;

  /// No description provided for @vehicle_soat_expiry_date_hint.
  ///
  /// In es, this message translates to:
  /// **'dd/mm/aaaa'**
  String get vehicle_soat_expiry_date_hint;

  /// No description provided for @vehicle_soat_save_button.
  ///
  /// In es, this message translates to:
  /// **'Guardar SOAT'**
  String get vehicle_soat_save_button;

  /// No description provided for @vehicle_soat_saved_successfully.
  ///
  /// In es, this message translates to:
  /// **'SOAT registrado exitosamente'**
  String get vehicle_soat_saved_successfully;

  /// No description provided for @vehicle_soat_data_added.
  ///
  /// In es, this message translates to:
  /// **'Datos del SOAT agregados'**
  String get vehicle_soat_data_added;

  /// No description provided for @vehicle_rtm_data_added.
  ///
  /// In es, this message translates to:
  /// **'Datos de la RTM agregados'**
  String get vehicle_rtm_data_added;

  /// No description provided for @vehicle_doc_expires_on.
  ///
  /// In es, this message translates to:
  /// **'Vence {date}'**
  String vehicle_doc_expires_on(String date);

  /// No description provided for @vehicle_soat_section_title.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get vehicle_soat_section_title;

  /// No description provided for @vehicle_soat_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'Confirmar SOAT'**
  String get vehicle_soat_confirm_title;

  /// No description provided for @vehicle_soat_confirm_button.
  ///
  /// In es, this message translates to:
  /// **'Confirmar SOAT'**
  String get vehicle_soat_confirm_button;

  /// No description provided for @vehicle_soat_confirm_verify.
  ///
  /// In es, this message translates to:
  /// **'Verifica los datos del SOAT'**
  String get vehicle_soat_confirm_verify;

  /// No description provided for @vehicle_soat_confirm_verify_sub.
  ///
  /// In es, this message translates to:
  /// **'Revisa y corrige la información antes de confirmar'**
  String get vehicle_soat_confirm_verify_sub;

  /// No description provided for @vehicle_soat_manual_section_title.
  ///
  /// In es, this message translates to:
  /// **'Ingresa los datos del SOAT'**
  String get vehicle_soat_manual_section_title;

  /// No description provided for @vehicle_soat_manual_section_sub.
  ///
  /// In es, this message translates to:
  /// **'Completa la información de tu seguro'**
  String get vehicle_soat_manual_section_sub;

  /// No description provided for @vehicle_soat_doc_uploaded.
  ///
  /// In es, this message translates to:
  /// **'Documento subido exitosamente'**
  String get vehicle_soat_doc_uploaded;

  /// No description provided for @vehicle_soat_status_valid.
  ///
  /// In es, this message translates to:
  /// **'SOAT vigente'**
  String get vehicle_soat_status_valid;

  /// No description provided for @vehicle_soat_status_valid_desc.
  ///
  /// In es, this message translates to:
  /// **'Tu SOAT estará vigente por {days} días más'**
  String vehicle_soat_status_valid_desc(int days);

  /// No description provided for @vehicle_soat_status_expires_today.
  ///
  /// In es, this message translates to:
  /// **'Vence hoy'**
  String get vehicle_soat_status_expires_today;

  /// No description provided for @vehicle_soat_status_expired_title.
  ///
  /// In es, this message translates to:
  /// **'SOAT vencido'**
  String get vehicle_soat_status_expired_title;

  /// No description provided for @vehicle_soat_status_expired_desc.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =1{Venció hace 1 día} other{Venció hace {days} días}}'**
  String vehicle_soat_status_expired_desc(int days);

  /// No description provided for @vehicle_soat_status_invalid_dates_title.
  ///
  /// In es, this message translates to:
  /// **'Fechas inválidas'**
  String get vehicle_soat_status_invalid_dates_title;

  /// No description provided for @vehicle_soat_status_invalid_dates_desc.
  ///
  /// In es, this message translates to:
  /// **'La fecha de inicio debe ser anterior al vencimiento'**
  String get vehicle_soat_status_invalid_dates_desc;

  /// No description provided for @vehicle_soat_status_pending.
  ///
  /// In es, this message translates to:
  /// **'Estado del SOAT'**
  String get vehicle_soat_status_pending;

  /// No description provided for @tracking_sosCallError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar la llamada.'**
  String get tracking_sosCallError;

  /// No description provided for @tracking_sosLocationError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener la ubicación del rider.'**
  String get tracking_sosLocationError;

  /// No description provided for @tracking_sosMapError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el mapa.'**
  String get tracking_sosMapError;

  /// No description provided for @tracking_sosSemanticsLabel.
  ///
  /// In es, this message translates to:
  /// **'Enviar alerta de emergencia'**
  String get tracking_sosSemanticsLabel;

  /// No description provided for @map_filterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get map_filterAll;

  /// No description provided for @map_filterActive.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get map_filterActive;

  /// No description provided for @map_filterStopped.
  ///
  /// In es, this message translates to:
  /// **'Detenidos'**
  String get map_filterStopped;

  /// No description provided for @map_filterSos.
  ///
  /// In es, this message translates to:
  /// **'SOS'**
  String get map_filterSos;

  /// No description provided for @map_searchParticipants.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre...'**
  String get map_searchParticipants;

  /// No description provided for @map_viewProfile.
  ///
  /// In es, this message translates to:
  /// **'Ver perfil'**
  String get map_viewProfile;

  /// No description provided for @map_emergencyCall.
  ///
  /// In es, this message translates to:
  /// **'Llamada de emergencia'**
  String get map_emergencyCall;

  /// No description provided for @map_locate.
  ///
  /// In es, this message translates to:
  /// **'Localizar'**
  String get map_locate;

  /// No description provided for @map_stopped.
  ///
  /// In es, this message translates to:
  /// **'Detenido'**
  String get map_stopped;

  /// No description provided for @map_geocodeError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener las coordenadas.'**
  String get map_geocodeError;

  /// Shown as a SnackBar when the Mapbox map fails to load tiles or style during a live ride.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el mapa.'**
  String get map_loadError;

  /// No description provided for @maintenance_summary_title.
  ///
  /// In es, this message translates to:
  /// **'Resumen de Mantenimientos'**
  String get maintenance_summary_title;

  /// No description provided for @maintenance_services_count.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get maintenance_services_count;

  /// No description provided for @maintenance_total_spent.
  ///
  /// In es, this message translates to:
  /// **'Total gastado'**
  String get maintenance_total_spent;

  /// No description provided for @maintenance_overdue_section.
  ///
  /// In es, this message translates to:
  /// **'ATRASADO'**
  String get maintenance_overdue_section;

  /// No description provided for @maintenance_upcoming_section.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMAMENTE'**
  String get maintenance_upcoming_section;

  /// No description provided for @maintenance_on_track_section.
  ///
  /// In es, this message translates to:
  /// **'AL DÍA'**
  String get maintenance_on_track_section;

  /// No description provided for @maintenance_status_done_badge.
  ///
  /// In es, this message translates to:
  /// **'Realizado'**
  String get maintenance_status_done_badge;

  /// No description provided for @maintenance_status_scheduled_badge.
  ///
  /// In es, this message translates to:
  /// **'Programado'**
  String get maintenance_status_scheduled_badge;

  /// No description provided for @maintenance_service_info.
  ///
  /// In es, this message translates to:
  /// **'Información del servicio'**
  String get maintenance_service_info;

  /// No description provided for @maintenance_service_date.
  ///
  /// In es, this message translates to:
  /// **'Fecha del servicio'**
  String get maintenance_service_date;

  /// No description provided for @maintenance_odometer_km.
  ///
  /// In es, this message translates to:
  /// **'Odómetro'**
  String get maintenance_odometer_km;

  /// No description provided for @maintenance_next_review.
  ///
  /// In es, this message translates to:
  /// **'Próxima revisión'**
  String get maintenance_next_review;

  /// No description provided for @maintenance_next_date_label.
  ///
  /// In es, this message translates to:
  /// **'Próxima fecha'**
  String get maintenance_next_date_label;

  /// No description provided for @maintenance_next_odometer_label.
  ///
  /// In es, this message translates to:
  /// **'Próximo odómetro'**
  String get maintenance_next_odometer_label;

  /// No description provided for @maintenance_expired_label.
  ///
  /// In es, this message translates to:
  /// **'vencido'**
  String get maintenance_expired_label;

  /// No description provided for @maintenance_modeScheduled.
  ///
  /// In es, this message translates to:
  /// **'Programado'**
  String get maintenance_modeScheduled;

  /// No description provided for @maintenance_statusOverdue.
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get maintenance_statusOverdue;

  /// No description provided for @garage_viewMaintenanceHistory.
  ///
  /// In es, this message translates to:
  /// **'Ver historial de mantenimientos'**
  String get garage_viewMaintenanceHistory;

  /// No description provided for @garage_completedServiceBadge.
  ///
  /// In es, this message translates to:
  /// **'HECHO'**
  String get garage_completedServiceBadge;

  /// No description provided for @garage_otherVehiclesSection.
  ///
  /// In es, this message translates to:
  /// **'OTROS VEHÍCULOS'**
  String get garage_otherVehiclesSection;

  /// No description provided for @garage_upToDate.
  ///
  /// In es, this message translates to:
  /// **'Al día'**
  String get garage_upToDate;

  /// No description provided for @garage_upcomingCount.
  ///
  /// In es, this message translates to:
  /// **'{count} próximo'**
  String garage_upcomingCount(int count);

  /// No description provided for @garage_mainVehicleBadge.
  ///
  /// In es, this message translates to:
  /// **'Principal'**
  String get garage_mainVehicleBadge;

  /// No description provided for @garage_odometerLabel.
  ///
  /// In es, this message translates to:
  /// **'odómetro'**
  String get garage_odometerLabel;

  /// No description provided for @garage_healthUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximo'**
  String get garage_healthUpcoming;

  /// No description provided for @garage_tapForDetail.
  ///
  /// In es, this message translates to:
  /// **'Toca para ver detalle del vehículo'**
  String get garage_tapForDetail;

  /// No description provided for @garage_seeDetail.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle'**
  String get garage_seeDetail;

  /// No description provided for @notification_loadMore.
  ///
  /// In es, this message translates to:
  /// **'Cargar más notificaciones'**
  String get notification_loadMore;

  /// No description provided for @notification_loadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las notificaciones'**
  String get notification_loadError;

  /// No description provided for @notification_loadErrorSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu conexión a internet e intenta de nuevo.'**
  String get notification_loadErrorSubtitle;

  /// No description provided for @notification_soat30d_title.
  ///
  /// In es, this message translates to:
  /// **'SOAT vence en 30 días'**
  String get notification_soat30d_title;

  /// No description provided for @notification_soat7d_title.
  ///
  /// In es, this message translates to:
  /// **'Tu SOAT vence en 7 días'**
  String get notification_soat7d_title;

  /// No description provided for @notification_soatDayOf_title.
  ///
  /// In es, this message translates to:
  /// **'Tu SOAT vence hoy'**
  String get notification_soatDayOf_title;

  /// No description provided for @notification_soat_subtitle.
  ///
  /// In es, this message translates to:
  /// **'{vehicleName} · Renuévalo para evitar multas'**
  String notification_soat_subtitle(String vehicleName);

  /// No description provided for @notification_soatDayOf_subtitle.
  ///
  /// In es, this message translates to:
  /// **'{vehicleName} · Renueva antes de salir'**
  String notification_soatDayOf_subtitle(String vehicleName);

  /// No description provided for @notification_newRegistration_title.
  ///
  /// In es, this message translates to:
  /// **'Nueva inscripción'**
  String get notification_newRegistration_title;

  /// No description provided for @notification_newRegistration_subtitle.
  ///
  /// In es, this message translates to:
  /// **'{riderName} quiere unirse a \"{eventName}\"'**
  String notification_newRegistration_subtitle(
    String riderName,
    String eventName,
  );

  /// No description provided for @notification_approved_title.
  ///
  /// In es, this message translates to:
  /// **'Inscripción aprobada'**
  String get notification_approved_title;

  /// No description provided for @notification_approved_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Estás inscrito a \"{eventName}\"'**
  String notification_approved_subtitle(String eventName);

  /// No description provided for @notification_rejected_title.
  ///
  /// In es, this message translates to:
  /// **'Inscripción rechazada'**
  String get notification_rejected_title;

  /// No description provided for @notification_rejected_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud para \"{eventName}\" no fue aprobada'**
  String notification_rejected_subtitle(String eventName);

  /// No description provided for @notification_bell_unread_label.
  ///
  /// In es, this message translates to:
  /// **'{count} notificaciones sin leer'**
  String notification_bell_unread_label(int count);

  /// No description provided for @notification_bell_label.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notification_bell_label;

  /// No description provided for @notification_item_accessibility_label.
  ///
  /// In es, this message translates to:
  /// **'Notificación: {title}, {time}'**
  String notification_item_accessibility_label(String title, String time);

  /// No description provided for @soat_page_upload_title.
  ///
  /// In es, this message translates to:
  /// **'Subir SOAT'**
  String get soat_page_upload_title;

  /// No description provided for @soat_page_status_title.
  ///
  /// In es, this message translates to:
  /// **'Mi SOAT'**
  String get soat_page_status_title;

  /// No description provided for @soat_upload_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona cómo quieres subir tu SOAT para {vehicleName}.'**
  String soat_upload_subtitle(String vehicleName);

  /// No description provided for @soat_manual_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa los datos del SOAT para {vehicleName}. Puedes subir el documento más adelante.'**
  String soat_manual_subtitle(String vehicleName);

  /// No description provided for @soat_source_camera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get soat_source_camera;

  /// No description provided for @soat_source_gallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get soat_source_gallery;

  /// No description provided for @soat_source_pdf.
  ///
  /// In es, this message translates to:
  /// **'Archivo PDF'**
  String get soat_source_pdf;

  /// No description provided for @soat_source_manual.
  ///
  /// In es, this message translates to:
  /// **'Ingresar manualmente'**
  String get soat_source_manual;

  /// No description provided for @soat_scan_button.
  ///
  /// In es, this message translates to:
  /// **'Escanear SOAT'**
  String get soat_scan_button;

  /// No description provided for @soat_scan_sheet_title.
  ///
  /// In es, this message translates to:
  /// **'Escanear documento'**
  String get soat_scan_sheet_title;

  /// No description provided for @soat_scan_loading.
  ///
  /// In es, this message translates to:
  /// **'Leyendo documento…'**
  String get soat_scan_loading;

  /// No description provided for @soat_scan_banner.
  ///
  /// In es, this message translates to:
  /// **'Datos extraídos del documento — revisa antes de guardar'**
  String get soat_scan_banner;

  /// No description provided for @soat_scan_banner_review.
  ///
  /// In es, this message translates to:
  /// **'Revisa con cuidado los campos resaltados antes de guardar'**
  String get soat_scan_banner_review;

  /// No description provided for @soat_scan_field_hint.
  ///
  /// In es, this message translates to:
  /// **'Dato extraído del documento'**
  String get soat_scan_field_hint;

  /// No description provided for @soat_autofill_banner_title.
  ///
  /// In es, this message translates to:
  /// **'Detectamos los datos de tu SOAT'**
  String get soat_autofill_banner_title;

  /// No description provided for @soat_autofill_banner_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Puedes autocompletar el formulario y revisar antes de guardar'**
  String get soat_autofill_banner_subtitle;

  /// No description provided for @soat_autofill_banner_button.
  ///
  /// In es, this message translates to:
  /// **'Autocompletar campos'**
  String get soat_autofill_banner_button;

  /// No description provided for @soat_scan_error_unreadable.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer el documento, ingresa los datos manualmente'**
  String get soat_scan_error_unreadable;

  /// No description provided for @soat_scan_error_permission.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos permiso de cámara o archivos para escanear el documento'**
  String get soat_scan_error_permission;

  /// No description provided for @soat_field_policy_number.
  ///
  /// In es, this message translates to:
  /// **'N.° de póliza'**
  String get soat_field_policy_number;

  /// No description provided for @soat_field_insurer.
  ///
  /// In es, this message translates to:
  /// **'Aseguradora'**
  String get soat_field_insurer;

  /// No description provided for @soat_field_start_date.
  ///
  /// In es, this message translates to:
  /// **'Fecha inicio'**
  String get soat_field_start_date;

  /// No description provided for @soat_field_expiry_date.
  ///
  /// In es, this message translates to:
  /// **'Fecha vencimiento'**
  String get soat_field_expiry_date;

  /// No description provided for @soat_save_data_btn.
  ///
  /// In es, this message translates to:
  /// **'Guardar datos'**
  String get soat_save_data_btn;

  /// No description provided for @soat_saving.
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get soat_saving;

  /// No description provided for @soat_manual_note.
  ///
  /// In es, this message translates to:
  /// **'Puedes subir el documento físico más adelante desde el detalle del vehículo.'**
  String get soat_manual_note;

  /// No description provided for @soat_status_no_soat.
  ///
  /// In es, this message translates to:
  /// **'Sin registrar'**
  String get soat_status_no_soat;

  /// No description provided for @soat_status_valid.
  ///
  /// In es, this message translates to:
  /// **'Vigente'**
  String get soat_status_valid;

  /// No description provided for @soat_status_expiring_soon.
  ///
  /// In es, this message translates to:
  /// **'Por vencer'**
  String get soat_status_expiring_soon;

  /// No description provided for @soat_status_expired.
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get soat_status_expired;

  /// No description provided for @soat_valid_title.
  ///
  /// In es, this message translates to:
  /// **'Tu SOAT está al día'**
  String get soat_valid_title;

  /// No description provided for @soat_expiring_title.
  ///
  /// In es, this message translates to:
  /// **'Tu SOAT vence pronto'**
  String get soat_expiring_title;

  /// No description provided for @soat_expired_title.
  ///
  /// In es, this message translates to:
  /// **'Tu SOAT está vencido'**
  String get soat_expired_title;

  /// No description provided for @soat_valid_days_remaining.
  ///
  /// In es, this message translates to:
  /// **'{count} días restantes'**
  String soat_valid_days_remaining(int count);

  /// No description provided for @soat_expiring_days_remaining.
  ///
  /// In es, this message translates to:
  /// **'{count} días restantes'**
  String soat_expiring_days_remaining(int count);

  /// No description provided for @soat_expired_days_ago.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Venció hace 1 día} other{Venció hace {count} días}}'**
  String soat_expired_days_ago(int count);

  /// No description provided for @soat_expiring_warning.
  ///
  /// In es, this message translates to:
  /// **'Te notificaremos 7 días antes del vencimiento. Renueva tu SOAT con anticipación para evitar multas.'**
  String get soat_expiring_warning;

  /// No description provided for @soat_expired_warning.
  ///
  /// In es, this message translates to:
  /// **'Circular sin SOAT vigente es una infracción. Renueva tu seguro lo antes posible.'**
  String get soat_expired_warning;

  /// No description provided for @soat_renew_btn.
  ///
  /// In es, this message translates to:
  /// **'Registrar nuevo SOAT'**
  String get soat_renew_btn;

  /// No description provided for @soat_view_document.
  ///
  /// In es, this message translates to:
  /// **'Ver documento'**
  String get soat_view_document;

  /// No description provided for @soat_edit_btn.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get soat_edit_btn;

  /// No description provided for @soat_edit_title.
  ///
  /// In es, this message translates to:
  /// **'Editar SOAT'**
  String get soat_edit_title;

  /// No description provided for @soat_doc_tap_to_open.
  ///
  /// In es, this message translates to:
  /// **'Toca para abrir'**
  String get soat_doc_tap_to_open;

  /// No description provided for @soat_doc_attached_title.
  ///
  /// In es, this message translates to:
  /// **'Documento adjunto'**
  String get soat_doc_attached_title;

  /// No description provided for @soat_doc_replace.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar archivo'**
  String get soat_doc_replace;

  /// No description provided for @soat_doc_change.
  ///
  /// In es, this message translates to:
  /// **'Cambiar archivo'**
  String get soat_doc_change;

  /// No description provided for @soat_doc_add_label.
  ///
  /// In es, this message translates to:
  /// **'Agregar documento SOAT'**
  String get soat_doc_add_label;

  /// No description provided for @soat_doc_add_hint.
  ///
  /// In es, this message translates to:
  /// **'Opcional · Imagen o PDF'**
  String get soat_doc_add_hint;

  /// No description provided for @soat_document_not_recognized.
  ///
  /// In es, this message translates to:
  /// **'Parece que este documento no es un SOAT. Verifica el archivo o completa los datos manualmente.'**
  String get soat_document_not_recognized;

  /// No description provided for @soat_add_doc_sheet_title.
  ///
  /// In es, this message translates to:
  /// **'Agregar documento'**
  String get soat_add_doc_sheet_title;

  /// No description provided for @soat_add_doc_camera_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Toma una foto del documento'**
  String get soat_add_doc_camera_subtitle;

  /// No description provided for @soat_add_doc_gallery_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige una imagen de tu galería'**
  String get soat_add_doc_gallery_subtitle;

  /// No description provided for @soat_add_doc_pdf_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un archivo PDF'**
  String get soat_add_doc_pdf_subtitle;

  /// No description provided for @soat_upload_error.
  ///
  /// In es, this message translates to:
  /// **'Error al subir. Archivo demasiado grande (máx. 10 MB).'**
  String get soat_upload_error;

  /// No description provided for @soat_expiry_after_start_error.
  ///
  /// In es, this message translates to:
  /// **'La fecha de vencimiento debe ser posterior a la fecha de inicio.'**
  String get soat_expiry_after_start_error;

  /// No description provided for @soat_delete_button.
  ///
  /// In es, this message translates to:
  /// **'Eliminar SOAT'**
  String get soat_delete_button;

  /// No description provided for @soat_delete_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar SOAT?'**
  String get soat_delete_confirm_title;

  /// No description provided for @soat_delete_confirm_message.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará la información del SOAT de este vehículo. Esta acción no se puede deshacer.'**
  String get soat_delete_confirm_message;

  /// No description provided for @soat_deleted_success.
  ///
  /// In es, this message translates to:
  /// **'SOAT eliminado'**
  String get soat_deleted_success;

  /// No description provided for @event_draftBadge.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get event_draftBadge;

  /// No description provided for @draft_myDraftsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis borradores'**
  String get draft_myDraftsTitle;

  /// No description provided for @draft_noDrafts.
  ///
  /// In es, this message translates to:
  /// **'No tienes borradores'**
  String get draft_noDrafts;

  /// No description provided for @draft_noDraftsHint.
  ///
  /// In es, this message translates to:
  /// **'Guarda un evento como borrador para editarlo y publicarlo después'**
  String get draft_noDraftsHint;

  /// No description provided for @draft_publish.
  ///
  /// In es, this message translates to:
  /// **'Publicar evento'**
  String get draft_publish;

  /// No description provided for @route_typeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de ruta'**
  String get route_typeLabel;

  /// No description provided for @route_simpleLabel.
  ///
  /// In es, this message translates to:
  /// **'Ruta simple (A→B)'**
  String get route_simpleLabel;

  /// No description provided for @route_customLabel.
  ///
  /// In es, this message translates to:
  /// **'Ruta personalizada'**
  String get route_customLabel;

  /// No description provided for @route_builder_title.
  ///
  /// In es, this message translates to:
  /// **'Crear ruta'**
  String get route_builder_title;

  /// No description provided for @route_builder_search_placeholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar un lugar...'**
  String get route_builder_search_placeholder;

  /// No description provided for @route_builder_search_placeholder_disabled.
  ///
  /// In es, this message translates to:
  /// **'Límite de 9 puntos alcanzado'**
  String get route_builder_search_placeholder_disabled;

  /// No description provided for @route_builder_section_title.
  ///
  /// In es, this message translates to:
  /// **'PUNTOS DE RUTA'**
  String get route_builder_section_title;

  /// No description provided for @route_builder_counter.
  ///
  /// In es, this message translates to:
  /// **'{count}/9 puntos'**
  String route_builder_counter(int count);

  /// No description provided for @route_builder_empty_hint.
  ///
  /// In es, this message translates to:
  /// **'Agrega puntos para construir tu ruta'**
  String get route_builder_empty_hint;

  /// No description provided for @route_builder_continue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get route_builder_continue;

  /// No description provided for @route_builder_limit_banner.
  ///
  /// In es, this message translates to:
  /// **'Has alcanzado el límite de 9 puntos. Elimina uno para agregar otro.'**
  String get route_builder_limit_banner;

  /// No description provided for @route_builder_pick_mode_button.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar en mapa'**
  String get route_builder_pick_mode_button;

  /// No description provided for @route_builder_pick_mode_confirm.
  ///
  /// In es, this message translates to:
  /// **'Añadir este punto'**
  String get route_builder_pick_mode_confirm;

  /// No description provided for @route_map_locating.
  ///
  /// In es, this message translates to:
  /// **'Obteniendo tu ubicación...'**
  String get route_map_locating;

  /// No description provided for @route_map_point_fallback_name.
  ///
  /// In es, this message translates to:
  /// **'Punto en el mapa'**
  String get route_map_point_fallback_name;

  /// No description provided for @route_edit_button.
  ///
  /// In es, this message translates to:
  /// **'Editar ruta'**
  String get route_edit_button;

  /// No description provided for @route_create_button.
  ///
  /// In es, this message translates to:
  /// **'Crear ruta'**
  String get route_create_button;

  /// No description provided for @ai_autoGenerateMessage.
  ///
  /// In es, this message translates to:
  /// **'Genera una descripción atractiva para este evento con la información disponible'**
  String get ai_autoGenerateMessage;

  /// No description provided for @route_point_start.
  ///
  /// In es, this message translates to:
  /// **'SALIDA'**
  String get route_point_start;

  /// No description provided for @route_point_waypoint.
  ///
  /// In es, this message translates to:
  /// **'WAYPOINT'**
  String get route_point_waypoint;

  /// No description provided for @route_point_end.
  ///
  /// In es, this message translates to:
  /// **'LLEGADA'**
  String get route_point_end;

  /// No description provided for @route_empty_hint.
  ///
  /// In es, this message translates to:
  /// **'Toca el card para crear tu ruta'**
  String get route_empty_hint;

  /// No description provided for @route_placeSearchError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar sugerencias'**
  String get route_placeSearchError;

  /// No description provided for @route_noPlacesFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron resultados'**
  String get route_noPlacesFound;

  /// No description provided for @map_pickLocation.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar en el mapa'**
  String get map_pickLocation;

  /// No description provided for @map_dragToPosition.
  ///
  /// In es, this message translates to:
  /// **'Mueve el mapa para posicionar el punto'**
  String get map_dragToPosition;

  /// No description provided for @map_confirmLocation.
  ///
  /// In es, this message translates to:
  /// **'Confirmar ubicación'**
  String get map_confirmLocation;

  /// No description provided for @map_searchingAddress.
  ///
  /// In es, this message translates to:
  /// **'Buscando dirección...'**
  String get map_searchingAddress;

  /// No description provided for @map_addressNotFound.
  ///
  /// In es, this message translates to:
  /// **'Dirección no encontrada'**
  String get map_addressNotFound;

  /// No description provided for @event_route_meeting_point_hint.
  ///
  /// In es, this message translates to:
  /// **'Punto de encuentro'**
  String get event_route_meeting_point_hint;

  /// No description provided for @event_route_destination_hint.
  ///
  /// In es, this message translates to:
  /// **'Destino final'**
  String get event_route_destination_hint;

  /// Restored SOAT upload UI key: vehicle_soat_camera_button
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get vehicle_soat_camera_button;

  /// Restored SOAT upload UI key: vehicle_soat_file_button
  ///
  /// In es, this message translates to:
  /// **'PDF'**
  String get vehicle_soat_file_button;

  /// Restored SOAT upload UI key: vehicle_soat_gallery_button
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get vehicle_soat_gallery_button;

  /// Restored SOAT upload UI key: vehicle_soat_option_manual_cta
  ///
  /// In es, this message translates to:
  /// **'Completar formulario'**
  String get vehicle_soat_option_manual_cta;

  /// Restored SOAT upload UI key: vehicle_soat_option_manual_desc
  ///
  /// In es, this message translates to:
  /// **'Completa los datos del SOAT de forma manual sin necesidad de subir un documento'**
  String get vehicle_soat_option_manual_desc;

  /// Restored SOAT upload UI key: vehicle_soat_option_manual_title
  ///
  /// In es, this message translates to:
  /// **'Ingresar manualmente'**
  String get vehicle_soat_option_manual_title;

  /// Restored SOAT upload UI key: vehicle_soat_option_upload_desc
  ///
  /// In es, this message translates to:
  /// **'Sube una foto o el PDF del SOAT y leeremos los datos automáticamente para ti'**
  String get vehicle_soat_option_upload_desc;

  /// Restored SOAT upload UI key: vehicle_soat_option_upload_title
  ///
  /// In es, this message translates to:
  /// **'Escanea tu SOAT'**
  String get vehicle_soat_option_upload_title;

  /// Restored SOAT upload UI key: vehicle_soat_upload_question
  ///
  /// In es, this message translates to:
  /// **'¿Cómo deseas registrar tu SOAT?'**
  String get vehicle_soat_upload_question;

  /// Restored SOAT upload UI key: vehicle_soat_upload_subtitle
  ///
  /// In es, this message translates to:
  /// **'Selecciona una opción para actualizar el SOAT de tu vehículo'**
  String get vehicle_soat_upload_subtitle;

  /// No description provided for @tecnomecanica_page_status_title.
  ///
  /// In es, this message translates to:
  /// **'Mi tecnomecánica'**
  String get tecnomecanica_page_status_title;

  /// No description provided for @tecnomecanica_edit_btn.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get tecnomecanica_edit_btn;

  /// No description provided for @tecnomecanica_valid_title.
  ///
  /// In es, this message translates to:
  /// **'Tu RTM está al día'**
  String get tecnomecanica_valid_title;

  /// No description provided for @tecnomecanica_expiring_title.
  ///
  /// In es, this message translates to:
  /// **'Tu RTM vence pronto'**
  String get tecnomecanica_expiring_title;

  /// No description provided for @tecnomecanica_expired_title.
  ///
  /// In es, this message translates to:
  /// **'Tu RTM está vencida'**
  String get tecnomecanica_expired_title;

  /// No description provided for @tecnomecanica_valid_days_remaining.
  ///
  /// In es, this message translates to:
  /// **'{count} días restantes'**
  String tecnomecanica_valid_days_remaining(int count);

  /// No description provided for @tecnomecanica_expired_days_ago.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Venció hace 1 día} other{Venció hace {count} días}}'**
  String tecnomecanica_expired_days_ago(int count);

  /// No description provided for @tecnomecanica_expiring_warning.
  ///
  /// In es, this message translates to:
  /// **'Programa tu revisión técnico-mecánica con anticipación para evitar sanciones.'**
  String get tecnomecanica_expiring_warning;

  /// No description provided for @tecnomecanica_expired_warning.
  ///
  /// In es, this message translates to:
  /// **'Circular sin revisión técnico-mecánica vigente es una infracción. Lleva tu moto a revisión lo antes posible.'**
  String get tecnomecanica_expired_warning;

  /// No description provided for @tecnomecanica_renew_btn.
  ///
  /// In es, this message translates to:
  /// **'Registrar nueva RTM'**
  String get tecnomecanica_renew_btn;

  /// No description provided for @tecnomecanica_field_cda_name.
  ///
  /// In es, this message translates to:
  /// **'CDA'**
  String get tecnomecanica_field_cda_name;

  /// No description provided for @tecnomecanica_field_start_date.
  ///
  /// In es, this message translates to:
  /// **'Fecha inicio'**
  String get tecnomecanica_field_start_date;

  /// No description provided for @tecnomecanica_field_expiry_date.
  ///
  /// In es, this message translates to:
  /// **'Fecha vencimiento'**
  String get tecnomecanica_field_expiry_date;

  /// No description provided for @tecnomecanica_field_document_url.
  ///
  /// In es, this message translates to:
  /// **'URL del documento'**
  String get tecnomecanica_field_document_url;

  /// No description provided for @tecnomecanica_delete_button.
  ///
  /// In es, this message translates to:
  /// **'Eliminar RTM'**
  String get tecnomecanica_delete_button;

  /// No description provided for @tecnomecanica_delete_confirm_title.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar RTM?'**
  String get tecnomecanica_delete_confirm_title;

  /// No description provided for @tecnomecanica_delete_confirm_message.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará la información de la revisión técnico-mecánica de este vehículo. Esta acción no se puede deshacer.'**
  String get tecnomecanica_delete_confirm_message;

  /// No description provided for @tecnomecanica_deleted_success.
  ///
  /// In es, this message translates to:
  /// **'RTM eliminada'**
  String get tecnomecanica_deleted_success;

  /// No description provided for @tecnomecanica_status_no_rtm.
  ///
  /// In es, this message translates to:
  /// **'Sin RTM registrada'**
  String get tecnomecanica_status_no_rtm;

  /// No description provided for @tecnomecanica_manual_note.
  ///
  /// In es, this message translates to:
  /// **'Registra los datos de tu revisión técnico-mecánica para hacer seguimiento de su vencimiento.'**
  String get tecnomecanica_manual_note;

  /// No description provided for @tecnomecanica_form_create_title.
  ///
  /// In es, this message translates to:
  /// **'Registrar RTM'**
  String get tecnomecanica_form_create_title;

  /// No description provided for @tecnomecanica_edit_title.
  ///
  /// In es, this message translates to:
  /// **'Editar RTM'**
  String get tecnomecanica_edit_title;

  /// No description provided for @tecnomecanica_form_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa los datos de la revisión técnico-mecánica de {vehicleName}.'**
  String tecnomecanica_form_subtitle(String vehicleName);

  /// No description provided for @tecnomecanica_save_data_btn.
  ///
  /// In es, this message translates to:
  /// **'Guardar datos'**
  String get tecnomecanica_save_data_btn;

  /// No description provided for @tecnomecanica_saving.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get tecnomecanica_saving;

  /// No description provided for @tecnomecanica_save_error.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la revisión técnico-mecánica. Intenta de nuevo.'**
  String get tecnomecanica_save_error;

  /// No description provided for @tecnomecanica_expiry_after_start_error.
  ///
  /// In es, this message translates to:
  /// **'La fecha de vencimiento debe ser posterior a la fecha de inicio.'**
  String get tecnomecanica_expiry_after_start_error;

  /// No description provided for @tecnomecanica_cda_name_hint.
  ///
  /// In es, this message translates to:
  /// **'Nombre del CDA'**
  String get tecnomecanica_cda_name_hint;

  /// No description provided for @tecnomecanica_date_hint.
  ///
  /// In es, this message translates to:
  /// **'dd/mm/aaaa'**
  String get tecnomecanica_date_hint;

  /// No description provided for @tecnomecanica_document_url_hint.
  ///
  /// In es, this message translates to:
  /// **'https://...'**
  String get tecnomecanica_document_url_hint;

  /// No description provided for @tecnomecanica_exemption_notice.
  ///
  /// In es, this message translates to:
  /// **'Los vehículos con menos de 2 años no están obligados a tener RTM. Puedes registrarla de todas formas para llevar el control.'**
  String get tecnomecanica_exemption_notice;

  /// No description provided for @vehicle_doc_rtm_status_valid.
  ///
  /// In es, this message translates to:
  /// **'Vigente'**
  String get vehicle_doc_rtm_status_valid;

  /// No description provided for @vehicle_doc_rtm_status_expiring_soon.
  ///
  /// In es, this message translates to:
  /// **'Por vencer'**
  String get vehicle_doc_rtm_status_expiring_soon;

  /// No description provided for @vehicle_doc_rtm_status_expired.
  ///
  /// In es, this message translates to:
  /// **'Vencida'**
  String get vehicle_doc_rtm_status_expired;

  /// No description provided for @ai_chatTitle.
  ///
  /// In es, this message translates to:
  /// **'Asistente IA'**
  String get ai_chatTitle;

  /// No description provided for @ai_chatHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu mensaje...'**
  String get ai_chatHint;

  /// No description provided for @ai_sendButton.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get ai_sendButton;

  /// No description provided for @ai_insertButton.
  ///
  /// In es, this message translates to:
  /// **'Insertar descripción'**
  String get ai_insertButton;

  /// No description provided for @ai_quotaRemaining.
  ///
  /// In es, this message translates to:
  /// **'{count} generaciones restantes'**
  String ai_quotaRemaining(int count);

  /// No description provided for @ai_quotaExhausted.
  ///
  /// In es, this message translates to:
  /// **'Has agotado tus generaciones de hoy'**
  String get ai_quotaExhausted;

  /// No description provided for @ai_errorQuotaUser.
  ///
  /// In es, this message translates to:
  /// **'Has alcanzado tu límite diario de generaciones con IA.'**
  String get ai_errorQuotaUser;

  /// No description provided for @ai_errorQuotaProject.
  ///
  /// In es, this message translates to:
  /// **'El servicio de IA está temporalmente no disponible. Intenta más tarde.'**
  String get ai_errorQuotaProject;

  /// No description provided for @ai_errorSafetyBlocked.
  ///
  /// In es, this message translates to:
  /// **'Tu mensaje fue bloqueado por filtros de seguridad. Por favor ajusta el contenido e intenta de nuevo.'**
  String get ai_errorSafetyBlocked;

  /// No description provided for @ai_errorNetwork.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar con el servicio de IA. Verifica tu conexión e intenta de nuevo.'**
  String get ai_errorNetwork;

  /// No description provided for @ai_retryButton.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get ai_retryButton;

  /// No description provided for @ai_confirmReplaceTitle.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar descripción'**
  String get ai_confirmReplaceTitle;

  /// No description provided for @ai_confirmReplaceMessage.
  ///
  /// In es, this message translates to:
  /// **'El editor ya tiene contenido. ¿Deseas reemplazarlo con la descripción generada?'**
  String get ai_confirmReplaceMessage;

  /// No description provided for @ai_emptyStateTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Hola! Soy tu asistente para crear descripciones'**
  String get ai_emptyStateTitle;

  /// No description provided for @ai_emptyStateSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Describe los puntos clave de tu rodada y te ayudaré a redactar una descripción atractiva'**
  String get ai_emptyStateSubtitle;

  /// No description provided for @ai_emptyStateExhaustedTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin generaciones disponibles'**
  String get ai_emptyStateExhaustedTitle;

  /// No description provided for @ai_emptyStateExhaustedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Has alcanzado tu límite diario. Las generaciones se renuevan cada día a medianoche.'**
  String get ai_emptyStateExhaustedSubtitle;

  /// No description provided for @ai_chatDisabledHint.
  ///
  /// In es, this message translates to:
  /// **'Sin generaciones disponibles hoy'**
  String get ai_chatDisabledHint;

  /// No description provided for @ai_messageCopied.
  ///
  /// In es, this message translates to:
  /// **'Mensaje copiado'**
  String get ai_messageCopied;

  /// No description provided for @ai_quotaInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'Generaciones de descripción'**
  String get ai_quotaInfoTitle;

  /// No description provided for @ai_quotaInfoDescription.
  ///
  /// In es, this message translates to:
  /// **'Cada vez que el asistente genera una descripción completa consume una generación de tu cuota diaria. Las preguntas de aclaración no cuentan.'**
  String get ai_quotaInfoDescription;

  /// No description provided for @ai_quotaInfoAvailableToday.
  ///
  /// In es, this message translates to:
  /// **'Disponibles hoy'**
  String get ai_quotaInfoAvailableToday;

  /// No description provided for @ai_quotaInfoExhausted.
  ///
  /// In es, this message translates to:
  /// **'Sin generaciones disponibles'**
  String get ai_quotaInfoExhausted;

  /// No description provided for @ai_quotaInfoCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{{count} generación} other{{count} generaciones}}'**
  String ai_quotaInfoCount(int count);

  /// No description provided for @ai_quotaInfoResetLabel.
  ///
  /// In es, this message translates to:
  /// **'Se reinicia'**
  String get ai_quotaInfoResetLabel;

  /// No description provided for @ai_quotaInfoResetValue.
  ///
  /// In es, this message translates to:
  /// **'cada día'**
  String get ai_quotaInfoResetValue;

  /// No description provided for @ai_error_quota_exceeded_user.
  ///
  /// In es, this message translates to:
  /// **'Has alcanzado tu límite diario de generaciones con IA.'**
  String get ai_error_quota_exceeded_user;

  /// No description provided for @ai_error_quota_exceeded_project.
  ///
  /// In es, this message translates to:
  /// **'El servicio de IA está temporalmente no disponible. Intenta más tarde.'**
  String get ai_error_quota_exceeded_project;

  /// No description provided for @ai_error_safety_blocked.
  ///
  /// In es, this message translates to:
  /// **'Tu mensaje fue bloqueado por filtros de seguridad. Por favor ajusta el contenido e intenta de nuevo.'**
  String get ai_error_safety_blocked;

  /// No description provided for @ai_error_network.
  ///
  /// In es, this message translates to:
  /// **'No se pudo conectar con el servicio de IA. Verifica tu conexión e intenta de nuevo.'**
  String get ai_error_network;

  /// No description provided for @event_step_basicInfo.
  ///
  /// In es, this message translates to:
  /// **'Básico'**
  String get event_step_basicInfo;

  /// No description provided for @event_step_details.
  ///
  /// In es, this message translates to:
  /// **'Desc'**
  String get event_step_details;

  /// No description provided for @event_step_route.
  ///
  /// In es, this message translates to:
  /// **'Ruta'**
  String get event_step_route;

  /// No description provided for @event_step_reviewAndPublish.
  ///
  /// In es, this message translates to:
  /// **'Revisar'**
  String get event_step_reviewAndPublish;

  /// No description provided for @event_step1_title.
  ///
  /// In es, this message translates to:
  /// **'Información básica'**
  String get event_step1_title;

  /// No description provided for @event_step1_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Portada, nombre, fecha, tipo y dificultad'**
  String get event_step1_subtitle;

  /// No description provided for @event_step2_title.
  ///
  /// In es, this message translates to:
  /// **'Descripción del evento'**
  String get event_step2_title;

  /// No description provided for @event_step2_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe o genera la descripción con IA'**
  String get event_step2_subtitle;

  /// No description provided for @event_step3_title.
  ///
  /// In es, this message translates to:
  /// **'Ruta y detalles'**
  String get event_step3_title;

  /// No description provided for @event_step3_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Recorrido y configuración del evento'**
  String get event_step3_subtitle;

  /// No description provided for @event_step4_title.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu evento'**
  String get event_step4_title;

  /// No description provided for @event_step4_subtitle.
  ///
  /// In es, this message translates to:
  /// **'Confirma los datos antes de publicar'**
  String get event_step4_subtitle;

  /// No description provided for @event_step4_editTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen del evento'**
  String get event_step4_editTitle;

  /// No description provided for @event_step4_editSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Toca Editar en cada sección para cambiarla'**
  String get event_step4_editSubtitle;

  /// No description provided for @event_step_done.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get event_step_done;

  /// No description provided for @event_step_close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get event_step_close;

  /// No description provided for @event_changesSaved.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados'**
  String get event_changesSaved;

  /// No description provided for @event_step_continue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get event_step_continue;

  /// No description provided for @event_step_back.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get event_step_back;

  /// No description provided for @event_step_of.
  ///
  /// In es, this message translates to:
  /// **'de'**
  String get event_step_of;

  /// No description provided for @event_step_saveDraft.
  ///
  /// In es, this message translates to:
  /// **'Guardar borrador'**
  String get event_step_saveDraft;

  /// No description provided for @event_step_progressLabel.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String event_step_progressLabel(int current, int total);

  /// No description provided for @event_step_review_basicSection.
  ///
  /// In es, this message translates to:
  /// **'Información básica'**
  String get event_step_review_basicSection;

  /// No description provided for @event_step_review_detailsSection.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get event_step_review_detailsSection;

  /// No description provided for @event_step_review_routeSection.
  ///
  /// In es, this message translates to:
  /// **'Ruta'**
  String get event_step_review_routeSection;

  /// No description provided for @event_step_review_editButton.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get event_step_review_editButton;

  /// No description provided for @event_step_review_noName.
  ///
  /// In es, this message translates to:
  /// **'Sin nombre'**
  String get event_step_review_noName;

  /// No description provided for @event_step_review_noDescription.
  ///
  /// In es, this message translates to:
  /// **'Sin descripción'**
  String get event_step_review_noDescription;

  /// No description provided for @event_step_review_noDate.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha'**
  String get event_step_review_noDate;

  /// No description provided for @event_step_review_noMeetingPoint.
  ///
  /// In es, this message translates to:
  /// **'Sin punto de encuentro'**
  String get event_step_review_noMeetingPoint;

  /// No description provided for @event_step_review_noDestination.
  ///
  /// In es, this message translates to:
  /// **'Sin destino'**
  String get event_step_review_noDestination;

  /// No description provided for @event_step_review_noRoute.
  ///
  /// In es, this message translates to:
  /// **'Sin ruta configurada'**
  String get event_step_review_noRoute;

  /// No description provided for @event_step_review_difficulty.
  ///
  /// In es, this message translates to:
  /// **'Dificultad'**
  String get event_step_review_difficulty;

  /// No description provided for @event_step_review_type.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get event_step_review_type;

  /// No description provided for @event_step_review_brands.
  ///
  /// In es, this message translates to:
  /// **'Marcas'**
  String get event_step_review_brands;

  /// No description provided for @event_step_review_allBrands.
  ///
  /// In es, this message translates to:
  /// **'Todas las marcas'**
  String get event_step_review_allBrands;

  /// No description provided for @event_step_review_maxParticipants.
  ///
  /// In es, this message translates to:
  /// **'Participantes'**
  String get event_step_review_maxParticipants;

  /// No description provided for @event_step_review_noLimit.
  ///
  /// In es, this message translates to:
  /// **'Sin límite'**
  String get event_step_review_noLimit;

  /// No description provided for @event_step_review_price.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get event_step_review_price;

  /// No description provided for @event_step_review_free.
  ///
  /// In es, this message translates to:
  /// **'Gratuito'**
  String get event_step_review_free;

  /// No description provided for @event_step_review_meetingPoint.
  ///
  /// In es, this message translates to:
  /// **'Punto de encuentro'**
  String get event_step_review_meetingPoint;

  /// No description provided for @event_step_review_destination.
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get event_step_review_destination;

  /// No description provided for @event_step_review_waypoints.
  ///
  /// In es, this message translates to:
  /// **'Puntos intermedios'**
  String get event_step_review_waypoints;

  /// No description provided for @event_step_review_publishButton.
  ///
  /// In es, this message translates to:
  /// **'Publicar evento'**
  String get event_step_review_publishButton;

  /// No description provided for @event_wizard_cancel_dialog_title.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar evento?'**
  String get event_wizard_cancel_dialog_title;

  /// No description provided for @event_wizard_cancel_dialog_body.
  ///
  /// In es, this message translates to:
  /// **'Perderás todo lo que has llenado hasta ahora.'**
  String get event_wizard_cancel_dialog_body;

  /// No description provided for @event_wizard_cancel_dialog_confirm.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get event_wizard_cancel_dialog_confirm;

  /// No description provided for @event_step_review_dateTimeSection.
  ///
  /// In es, this message translates to:
  /// **'Fecha y hora'**
  String get event_step_review_dateTimeSection;

  /// No description provided for @event_step_review_date.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get event_step_review_date;

  /// No description provided for @event_step_review_meetingTime.
  ///
  /// In es, this message translates to:
  /// **'Hora inicio'**
  String get event_step_review_meetingTime;

  /// No description provided for @event_step_review_multiDay.
  ///
  /// In es, this message translates to:
  /// **'Varios días'**
  String get event_step_review_multiDay;

  /// No description provided for @event_step_review_yes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get event_step_review_yes;

  /// No description provided for @event_step_review_no.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get event_step_review_no;

  /// No description provided for @event_step_review_coverLoaded.
  ///
  /// In es, this message translates to:
  /// **'Imagen cargada ✓'**
  String get event_step_review_coverLoaded;

  /// No description provided for @event_step_review_coverNone.
  ///
  /// In es, this message translates to:
  /// **'Sin portada'**
  String get event_step_review_coverNone;

  /// No description provided for @event_step_review_descAdded.
  ///
  /// In es, this message translates to:
  /// **'Añadida ✓'**
  String get event_step_review_descAdded;

  /// No description provided for @event_step_review_nameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get event_step_review_nameLabel;

  /// No description provided for @event_step_review_descLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get event_step_review_descLabel;

  /// No description provided for @event_step_review_coverLabel.
  ///
  /// In es, this message translates to:
  /// **'Portada'**
  String get event_step_review_coverLabel;

  /// No description provided for @event_cover_picker_title.
  ///
  /// In es, this message translates to:
  /// **'Portada del evento'**
  String get event_cover_picker_title;

  /// No description provided for @event_cover_picker_gallery.
  ///
  /// In es, this message translates to:
  /// **'Subir desde galería'**
  String get event_cover_picker_gallery;

  /// No description provided for @event_cover_picker_change.
  ///
  /// In es, this message translates to:
  /// **'Cambiar imagen'**
  String get event_cover_picker_change;

  /// No description provided for @event_cover_picker_remove.
  ///
  /// In es, this message translates to:
  /// **'Eliminar portada'**
  String get event_cover_picker_remove;
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
