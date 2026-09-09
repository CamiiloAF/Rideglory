import 'package:freezed_annotation/freezed_annotation.dart';

import 'vehicle_document.dart';

part 'vehicle_documents_summary.freezed.dart';

/// SOAT y RTM de una moto en una sola consulta: se muestran juntos en la
/// fila ancha de documentos, así que no valen como "resultados
/// independientes" (regla de `ResultState`) — es un único resultado
/// combinado.
@freezed
abstract class VehicleDocumentsSummary with _$VehicleDocumentsSummary {
  const factory VehicleDocumentsSummary({
    VehicleDocument? soat,
    VehicleDocument? rtm,
  }) = _VehicleDocumentsSummary;
}
