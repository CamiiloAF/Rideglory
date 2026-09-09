import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_document.freezed.dart';

/// Tipo de documento legal de una moto.
enum DocumentKind { soat, rtm }

/// Estado de vigencia de un documento, puro en función de la fecha: nunca
/// se calcula en la UI para que el chip y la alerta de galería coincidan.
enum DocumentStatus { valid, expiringSoon, expired }

/// Un documento (SOAT o RTM) de una moto.
@freezed
abstract class VehicleDocument with _$VehicleDocument {
  const factory VehicleDocument({
    required String id,
    required String vehicleId,
    required DocumentKind kind,
    required DateTime expiryDate,
    required bool reminderEnabled,
    String? number,
    String? issuer,
    DateTime? startDate,
    String? filePath,
  }) = _VehicleDocument;

  const VehicleDocument._();

  static const int _expiringSoonWindowDays = 30;

  DocumentStatus statusAt(DateTime now) {
    final daysLeft = expiryDate.difference(now).inDays;
    if (daysLeft < 0) return DocumentStatus.expired;
    if (daysLeft <= _expiringSoonWindowDays) return DocumentStatus.expiringSoon;
    return DocumentStatus.valid;
  }
}
