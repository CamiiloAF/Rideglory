import '../../../core/utils/spanish_date_format.dart';
import 'maintenance.dart';
import 'maintenance_history_entry.dart';

/// Agrupa el historial por mes (más reciente primero) y calcula, para cada
/// registro, cuánto duró el anterior del mismo tipo en la misma moto.
abstract final class MaintenanceHistoryGrouping {
  static List<MaintenanceHistoryGroup> build(List<Maintenance> maintenances) {
    final byVehicleType = <String, List<Maintenance>>{};
    for (final maintenance in maintenances) {
      final key = '${maintenance.vehicleId}::${maintenance.type}';
      byVehicleType.putIfAbsent(key, () => []).add(maintenance);
    }
    for (final list in byVehicleType.values) {
      list.sort((a, b) => a.serviceDate.compareTo(b.serviceDate));
    }

    final previousOdometerById = <String, int>{};
    for (final list in byVehicleType.values) {
      for (var i = 1; i < list.length; i++) {
        previousOdometerById[list[i].id] = list[i - 1].odometer;
      }
    }

    final sortedDesc = [...maintenances]
      ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

    final groups = <String, List<MaintenanceHistoryEntry>>{};
    for (final maintenance in sortedDesc) {
      final label = SpanishDateFormat.monthYearUpper(maintenance.serviceDate);
      groups
          .putIfAbsent(label, () => [])
          .add(
            MaintenanceHistoryEntry(
              maintenance: maintenance,
              previousOdometer: previousOdometerById[maintenance.id],
            ),
          );
    }

    return groups.entries
        .map(
          (entry) => MaintenanceHistoryGroup(
            monthLabel: entry.key,
            entries: entry.value,
          ),
        )
        .toList();
  }

  /// Registros anteriores del mismo tipo y moto que [maintenance],
  /// más recientes primero (para el detalle: "Antes, en esta moto").
  static List<MaintenanceHistoryEntry> previousOf(
    Maintenance maintenance,
    List<Maintenance> all,
  ) {
    final sameGroup =
        all
            .where(
              (item) =>
                  item.vehicleId == maintenance.vehicleId &&
                  item.type == maintenance.type &&
                  item.id != maintenance.id &&
                  item.serviceDate.isBefore(maintenance.serviceDate),
            )
            .toList()
          ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

    final entries = <MaintenanceHistoryEntry>[];
    for (var i = 0; i < sameGroup.length; i++) {
      final current = sameGroup[i];
      final previousOdometer = i + 1 < sameGroup.length
          ? sameGroup[i + 1].odometer
          : null;
      entries.add(
        MaintenanceHistoryEntry(
          maintenance: current,
          previousOdometer: previousOdometer,
        ),
      );
    }
    return entries;
  }
}
