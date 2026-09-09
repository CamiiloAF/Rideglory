/// Preferencias de solo-dispositivo: no tienen columna en `profiles` porque
/// no necesitan sincronizarse entre dispositivos. "Notificaciones" gatea si
/// el token FCM del dispositivo sigue registrado; "compartir datos de uso"
/// gatea `FirebaseAnalytics.setAnalyticsCollectionEnabled`.
abstract class AppPreferencesRepository {
  Future<bool> getNotificationsEnabled();

  Future<void> setNotificationsEnabled(bool enabled);

  Future<bool> getAnalyticsEnabled();

  Future<void> setAnalyticsEnabled(bool enabled);
}
