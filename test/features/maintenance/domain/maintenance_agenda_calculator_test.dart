import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/maintenance/domain/maintenance.dart';
import 'package:rideglory/features/maintenance/domain/maintenance_agenda_calculator.dart';
import 'package:rideglory/features/maintenance/domain/maintenance_agenda_item.dart';
import 'package:rideglory/features/maintenance/domain/vehicle_option.dart';

void main() {
  final now = DateTime(2026, 8, 15);
  const vehicle = VehicleOption(
    id: 'v1',
    displayName: 'Yamaha MT-03',
    chipLabel: 'MT-03',
    currentMileage: 18450,
    isMain: true,
  );

  Maintenance buildMaintenance({
    String id = 'm1',
    String type = 'Cambio de aceite y filtro',
    int odometer = 10000,
    DateTime? serviceDate,
    int? nextOdometer,
    DateTime? nextDate,
  }) {
    return Maintenance(
      id: id,
      vehicleId: vehicle.id,
      vehicleDisplayName: vehicle.displayName,
      type: type,
      serviceDate: serviceDate ?? DateTime(2026, 1, 1),
      odometer: odometer,
      nextOdometer: nextOdometer,
      nextDate: nextDate,
    );
  }

  group('MaintenanceAgendaCalculator', () {
    test(
      'marks a km-based reminder as overdue when the vehicle already passed it',
      () {
        final maintenance = buildMaintenance(nextOdometer: 18000);

        final items = MaintenanceAgendaCalculator.compute(
          maintenances: [maintenance],
          vehicles: [vehicle],
          now: now,
        );

        expect(items, hasLength(1));
        expect(items.single.urgency, MaintenanceUrgency.overdue);
        expect(items.single.metric, MaintenanceAgendaMetric.kilometers);
        expect(items.single.value, 450);
      },
    );

    test('marks a km-based reminder as upcoming when there is room left', () {
      final maintenance = buildMaintenance(nextOdometer: 20000);

      final items = MaintenanceAgendaCalculator.compute(
        maintenances: [maintenance],
        vehicles: [vehicle],
        now: now,
      );

      expect(items.single.urgency, MaintenanceUrgency.upcoming);
      expect(items.single.value, 1550);
    });

    test('marks a date-based reminder due within 30 days as dueSoon', () {
      final maintenance = buildMaintenance(nextDate: DateTime(2026, 8, 27));

      final items = MaintenanceAgendaCalculator.compute(
        maintenances: [maintenance],
        vehicles: [vehicle],
        now: now,
      );

      expect(items.single.urgency, MaintenanceUrgency.dueSoon);
      expect(items.single.metric, MaintenanceAgendaMetric.days);
      expect(items.single.value, 12);
    });

    test('prefers the most urgent of km and date when both are set', () {
      final maintenance = buildMaintenance(
        nextOdometer: 25000, // far away
        nextDate: DateTime(2026, 8, 10), // already overdue
      );

      final items = MaintenanceAgendaCalculator.compute(
        maintenances: [maintenance],
        vehicles: [vehicle],
        now: now,
      );

      expect(items.single.urgency, MaintenanceUrgency.overdue);
      expect(items.single.metric, MaintenanceAgendaMetric.days);
    });

    test('ignores maintenances without a reminder', () {
      final maintenance = buildMaintenance();

      final items = MaintenanceAgendaCalculator.compute(
        maintenances: [maintenance],
        vehicles: [vehicle],
        now: now,
      );

      expect(items, isEmpty);
    });

    test('keeps only the latest record per vehicle+type', () {
      final older = buildMaintenance(
        id: 'm1',
        serviceDate: DateTime(2026, 1, 1),
        nextOdometer: 15000,
      );
      final newer = buildMaintenance(
        id: 'm2',
        serviceDate: DateTime(2026, 6, 1),
        nextOdometer: 20000,
      );

      final items = MaintenanceAgendaCalculator.compute(
        maintenances: [older, newer],
        vehicles: [vehicle],
        now: now,
      );

      expect(items, hasLength(1));
      expect(items.single.sourceMaintenanceId, 'm2');
    });

    test('sorts by urgency (overdue first) and then by value', () {
      final overdue = buildMaintenance(id: 'a', type: 'A', nextOdometer: 18000);
      final upcomingClose = buildMaintenance(
        id: 'b',
        type: 'B',
        nextOdometer: 18500,
      );
      final upcomingFar = buildMaintenance(
        id: 'c',
        type: 'C',
        nextOdometer: 20000,
      );

      final items = MaintenanceAgendaCalculator.compute(
        maintenances: [upcomingFar, overdue, upcomingClose],
        vehicles: [vehicle],
        now: now,
      );

      expect(items.map((item) => item.sourceMaintenanceId), ['a', 'b', 'c']);
    });
  });
}
