import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_document_alert.freezed.dart';

/// Tipo de documento resumido para la alerta de la celda de galería.
enum DocumentAlertKind { soat, rtm }

enum DocumentAlertSeverity { warning, critical }

/// Alerta de documento próximo a vencer o vencido, mostrada como chip sobre
/// la foto de la moto en la galería. Puramente datos: el texto final se
/// arma en `presentation` con `l10n`, nunca aquí.
@freezed
abstract class VehicleDocumentAlert with _$VehicleDocumentAlert {
  const factory VehicleDocumentAlert({
    required DocumentAlertKind kind,
    required DocumentAlertSeverity severity,

    /// Días hasta el vencimiento; negativo si ya venció.
    required int daysUntilExpiry,
  }) = _VehicleDocumentAlert;

  const VehicleDocumentAlert._();

  /// De la lista de vencimientos de una moto (SOAT y RTM), la alerta más
  /// urgente: primero cualquier documento vencido (el más reciente en
  /// vencer), y si no hay ninguno, el que esté por vencer dentro de 30 días.
  static VehicleDocumentAlert? mostUrgent(
    List<({DocumentAlertKind kind, DateTime expiryDate})> documents,
    DateTime now,
  ) {
    ({DocumentAlertKind kind, DateTime expiryDate})? worstExpired;
    ({DocumentAlertKind kind, DateTime expiryDate})? soonestUpcoming;

    for (final document in documents) {
      final daysLeft = document.expiryDate.difference(now).inDays;
      if (daysLeft < 0) {
        if (worstExpired == null || document.expiryDate.isBefore(worstExpired.expiryDate)) {
          worstExpired = document;
        }
      } else if (daysLeft <= 30) {
        if (soonestUpcoming == null || document.expiryDate.isBefore(soonestUpcoming.expiryDate)) {
          soonestUpcoming = document;
        }
      }
    }

    final chosen = worstExpired ?? soonestUpcoming;
    if (chosen == null) return null;

    return VehicleDocumentAlert(
      kind: chosen.kind,
      severity: worstExpired != null ? DocumentAlertSeverity.critical : DocumentAlertSeverity.warning,
      daysUntilExpiry: chosen.expiryDate.difference(now).inDays,
    );
  }
}
