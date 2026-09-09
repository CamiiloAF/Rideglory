/// Nombres y paths de ruta centralizados.
abstract final class AppRoutes {
  static const String welcome = 'welcome';
  static const String welcomePath = '/welcome';

  static const String authEmailLogin = 'auth-email-login';
  static const String authEmailLoginPath = '/welcome/correo';

  static const String authEmailRegister = 'auth-email-register';
  static const String authEmailRegisterPath = '/welcome/crear-cuenta';

  static const String authForgotPassword = 'auth-forgot-password';
  static const String authForgotPasswordPath = '/welcome/recuperar';

  static const String maintenance = 'maintenance';
  static const String maintenancePath = '/maintenance';

  static const String events = 'events';
  static const String eventsPath = '/events';

  static const String garage = 'garage';
  static const String garagePath = '/garage';

  static const String vehicleAdd = 'vehicle-add';
  static const String vehicleAddPath = 'add';

  static const String vehicleEdit = 'vehicle-edit';
  static const String vehicleEditPath = 'edit';

  static const String brandPicker = 'brand-picker';
  static const String brandPickerPath = 'brand';

  static const String documentViewer = 'document-viewer';
  static const String documentViewerPath = 'documents/:kind';

  static const String documentUpload = 'document-upload';
  static const String documentUploadPath = 'documents/:kind/upload';

  static const String profile = 'profile';
  static const String profilePath = '/profile';

  static const String profileSettings = 'profile-settings';
  static const String profileSettingsPath = '/profile/ajustes';

  static const String profileEdit = 'profile-edit';
  static const String profileEditPath = '/profile/editar';

  static const String profileEmergencyContact = 'profile-emergency-contact';
  static const String profileEmergencyContactPath = '/profile/emergencia';

  static const String profileConsents = 'profile-consents';
  static const String profileConsentsPath = '/profile/consentimientos';

  static const String profileDeleteAccount = 'profile-delete-account';
  static const String profileDeleteAccountPath = '/profile/borrar-cuenta';

  static const String profileDeleteAccountProgress =
      'profile-delete-account-progress';
  static const String profileDeleteAccountProgressPath =
      '/profile/borrar-cuenta/progreso';

  static const String profileDeleteAccountBlocked =
      'profile-delete-account-blocked';
  static const String profileDeleteAccountBlockedPath =
      '/profile/borrar-cuenta/bloqueado';
}
