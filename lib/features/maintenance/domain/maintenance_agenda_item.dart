import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_agenda_item.freezed.dart';

/// Urgencia de un ítem de agenda. El texto y el ícono cambian con ella, no
/// solo el color (regla de contexto moto: comprensible en menos de 2s).
enum MaintenanceUrgency { overdue, dueSoon, upcoming }

/// Unidad en la que se expresa cuánto falta (o cuánto se pasó) para el
/// próximo servicio.
enum MaintenanceAgendaMetric { kilometers, days }

/// Un servicio próximo (o vencido) de una moto, calculado a partir del
/// último registro de ese tipo y el odómetro actual de la moto.
@freezed
abstract class MaintenanceAgendaItem with _$MaintenanceAgendaItem {
  const factory MaintenanceAgendaItem({
    required String sourceMaintenanceId,
    required String vehicleId,
    required String vehicleDisplayName,
    required String type,
    required MaintenanceUrgency urgency,
    required MaintenanceAgendaMetric metric,

    /// Magnitud siempre positiva: km u días de diferencia con el límite,
    /// ya sea que falten (`upcoming`/`dueSoon`) o que ya se hayan pasado
    /// (`overdue`).
    required int value,
  }) = _MaintenanceAgendaItem;
}
