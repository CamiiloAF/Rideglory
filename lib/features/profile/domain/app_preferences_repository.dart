import 'package:dartz/dartz.dart';

import '../../../core/exceptions/domain_exception.dart';

/// Preferencias de solo-dispositivo: no tienen columna en `profiles` porque
/// no necesitan sincronizarse entre dispositivos. "Notificaciones" gatea si
/// el token FCM del dispositivo sigue registrado; "compartir datos de uso"
/// gatea `FirebaseAnalytics.setAnalyticsCollectionEnabled`.
abstract class AppPreferencesRepository {
  Future<Either<DomainException, bool>> getNotificationsEnabled();

  Future<Either<DomainException, Unit>> setNotificationsEnabled(bool enabled);

  Future<Either<DomainException, bool>> getAnalyticsEnabled();

  Future<Either<DomainException, Unit>> setAnalyticsEnabled(bool enabled);
}
