import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/exceptions/domain_exception.dart';
import '../domain/app_preferences_repository.dart';
import '../domain/profile_error_code.dart';

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
  Future<Either<DomainException, bool>> getNotificationsEnabled() async {
    try {
      final value =
          _sharedPreferences.getBool(_notificationsEnabledKey) ?? true;
      return Right(value);
    } catch (error) {
      return const Left(
        DomainException(message: ProfileErrorCode.preferencesUnavailable),
      );
    }
  }

  @override
  Future<Either<DomainException, Unit>> setNotificationsEnabled(
    bool enabled,
  ) async {
    try {
      await _sharedPreferences.setBool(_notificationsEnabledKey, enabled);
      return const Right(unit);
    } catch (error) {
      return const Left(
        DomainException(message: ProfileErrorCode.preferencesUnavailable),
      );
    }
  }

  @override
  Future<Either<DomainException, bool>> getAnalyticsEnabled() async {
    try {
      final value = _sharedPreferences.getBool(_analyticsEnabledKey) ?? true;
      return Right(value);
    } catch (error) {
      return const Left(
        DomainException(message: ProfileErrorCode.preferencesUnavailable),
      );
    }
  }

  @override
  Future<Either<DomainException, Unit>> setAnalyticsEnabled(
    bool enabled,
  ) async {
    try {
      await _sharedPreferences.setBool(_analyticsEnabledKey, enabled);
      return const Right(unit);
    } catch (error) {
      return const Left(
        DomainException(message: ProfileErrorCode.preferencesUnavailable),
      );
    }
  }
}
