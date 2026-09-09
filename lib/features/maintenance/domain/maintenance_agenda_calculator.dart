import 'maintenance.dart';
import 'maintenance_agenda_item.dart';
import 'vehicle_option.dart';

/// Deriva la agenda (próximos servicios) a partir del historial de
/// mantenimientos: para cada combinación moto+tipo con recordatorio,
/// compara el último registro contra el odómetro actual de la moto y la
/// fecha de hoy, y decide qué tan urgente es.
///
/// Puro: sin Flutter, sin I/O, fácil de probar con `now` inyectado.
abstract final class MaintenanceAgendaCalculator {
  static List<MaintenanceAgendaItem> compute({
    required List<Maintenance> maintenances,
    required List<VehicleOption> vehicles,
    required DateTime now,
  }) {
    final mileageByVehicle = {
      for (final vehicle in vehicles) vehicle.id: vehicle.currentMileage,
    };

    final latestByVehicleAndType = <String, Maintenance>{};
    for (final maintenance in maintenances) {
      if (!maintenance.hasReminder) continue;
      final key = '${maintenance.vehicleId}::${maintenance.type}';
      final current = latestByVehicleAndType[key];
      if (current == null ||
          maintenance.serviceDate.isAfter(current.serviceDate)) {
        latestByVehicleAndType[key] = maintenance;
      }
    }

    final items = <MaintenanceAgendaItem>[];
    for (final maintenance in latestByVehicleAndType.values) {
      final currentMileage = mileageByVehicle[maintenance.vehicleId];
      final item = _toAgendaItem(maintenance, currentMileage, now);
      if (item != null) items.add(item);
    }

    items.sort(_byUrgencyThenValue);
    return items;
  }

  static MaintenanceAgendaItem? _toAgendaItem(
    Maintenance maintenance,
    int? currentMileage,
    DateTime now,
  ) {
    final kmState = maintenance.nextOdometer != null && currentMileage != null
        ? _kmState(currentMileage, maintenance.nextOdometer!)
        : null;
    final dateState = maintenance.nextDate != null
        ? _dateState(now, maintenance.nextDate!)
        : null;

    final chosen = _mostUrgent(kmState, dateState);
    if (chosen == null) return null;

    return MaintenanceAgendaItem(
      sourceMaintenanceId: maintenance.id,
      vehicleId: maintenance.vehicleId,
      vehicleDisplayName: maintenance.vehicleDisplayName,
      type: maintenance.type,
      urgency: chosen.urgency,
      metric: chosen.metric,
      value: chosen.value,
    );
  }

  static _AgendaState _kmState(int currentMileage, int nextOdometer) {
    final diff = nextOdometer - currentMileage;
    if (diff <= 0) {
      return _AgendaState(
        MaintenanceUrgency.overdue,
        MaintenanceAgendaMetric.kilometers,
        -diff,
      );
    }
    return _AgendaState(
      MaintenanceUrgency.upcoming,
      MaintenanceAgendaMetric.kilometers,
      diff,
    );
  }

  static _AgendaState _dateState(DateTime now, DateTime nextDate) {
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDate.year, nextDate.month, nextDate.day);
    final days = due.difference(today).inDays;
    if (days <= 0) {
      return _AgendaState(
        MaintenanceUrgency.overdue,
        MaintenanceAgendaMetric.days,
        -days,
      );
    }
    if (days <= 30) {
      return _AgendaState(
        MaintenanceUrgency.dueSoon,
        MaintenanceAgendaMetric.days,
        days,
      );
    }
    return _AgendaState(
      MaintenanceUrgency.upcoming,
      MaintenanceAgendaMetric.days,
      days,
    );
  }

  /// El más urgente gana; si empatan en urgencia, se prefiere el kilometraje
  /// porque es lo que el rider puede verificar de inmediato en el odómetro.
  static _AgendaState? _mostUrgent(_AgendaState? a, _AgendaState? b) {
    if (a == null) return b;
    if (b == null) return a;
    if (_severity(a.urgency) != _severity(b.urgency)) {
      return _severity(a.urgency) > _severity(b.urgency) ? a : b;
    }
    return a;
  }

  static int _severity(MaintenanceUrgency urgency) => switch (urgency) {
    MaintenanceUrgency.overdue => 2,
    MaintenanceUrgency.dueSoon => 1,
    MaintenanceUrgency.upcoming => 0,
  };

  static int _byUrgencyThenValue(
    MaintenanceAgendaItem a,
    MaintenanceAgendaItem b,
  ) {
    final severityDiff = _severity(b.urgency) - _severity(a.urgency);
    if (severityDiff != 0) return severityDiff;
    return a.value.compareTo(b.value);
  }
}

class _AgendaState {
  const _AgendaState(this.urgency, this.metric, this.value);

  final MaintenanceUrgency urgency;
  final MaintenanceAgendaMetric metric;
  final int value;
}
