import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_preferences_repository.dart';

const _notificationsEnabledKey = 'profile.notifications_enabled';
const _analyticsEnabledKey = 'profile.analytics_enabled';

/// Preferencias de solo-dispositivo persistidas con `shared_preferences`.
/// Ninguna de las dos tiene columna en `profiles`: no necesitan
/// sincronizarse entre dispositivos (ver `AppPreferencesRepository`).
@LazySingleton(as: AppPreferencesRepository)
class AppPreferencesRepositoryImpl implements AppPreferencesRepository {
  AppPreferencesRepositoryImpl(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  @override
  Future<bool> getNotificationsEnabled() async {
    return _sharedPreferences.getBool(_notificationsEnabledKey) ?? true;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _sharedPreferences.setBool(_notificationsEnabledKey, enabled);
  }

  @override
  Future<bool> getAnalyticsEnabled() async {
    return _sharedPreferences.getBool(_analyticsEnabledKey) ?? true;
  }

  @override
  Future<void> setAnalyticsEnabled(bool enabled) async {
    await _sharedPreferences.setBool(_analyticsEnabledKey, enabled);
  }
}
