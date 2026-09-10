import 'package:freezed_annotation/freezed_annotation.dart';

import 'sos_status.dart';

part 'sos_alert.freezed.dart';

/// Una fila de la vista `sos_alerts_visible`: la alerta confirmada por el
/// servidor. D19: solo la cierra el rider que la emitió o el organizador
/// (`closedBy`); nunca una desconexión ni el fin del evento.
@freezed
abstract class SosAlert with _$SosAlert {
  const factory SosAlert({
    required String id,
    required String eventId,
    required String userId,
    required String riderName,
    required double lat,
    required double lng,
    required SosStatus status,
    required DateTime createdAt,
    String? riderPhone,
    double? accuracyM,
    String? message,
    DateTime? closedAt,
    String? closedBy,
  }) = _SosAlert;
}
