import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/maintenance/domain/maintenance.dart';
import 'package:rideglory/features/maintenance/domain/maintenance_history_grouping.dart';

void main() {
  Maintenance build({
    required String id,
    required DateTime serviceDate,
    required int odometer,
    String type = 'Cambio de aceite',
    String vehicleId = 'v1',
  }) {
    return Maintenance(
      id: id,
      vehicleId: vehicleId,
      vehicleDisplayName: 'Yamaha MT-03',
      type: type,
      serviceDate: serviceDate,
      odometer: odometer,
    );
  }

  group('MaintenanceHistoryGrouping.build', () {
    test('groups by month label, most recent month first', () {
      final august = build(
        id: 'a',
        serviceDate: DateTime(2026, 8, 12),
        odometer: 18450,
      );
      final july = build(
        id: 'b',
        serviceDate: DateTime(2026, 7, 3),
        odometer: 15100,
      );

      final groups = MaintenanceHistoryGrouping.build([july, august]);

      expect(groups.map((group) => group.monthLabel), [
        'AGOSTO 2026',
        'JULIO 2026',
      ]);
    });

    test(
      'computes duration against the previous record of the same type+vehicle',
      () {
        final first = build(
          id: 'a',
          serviceDate: DateTime(2026, 1, 1),
          odometer: 10000,
        );
        final second = build(
          id: 'b',
          serviceDate: DateTime(2026, 6, 1),
          odometer: 15000,
        );

        final groups = MaintenanceHistoryGrouping.build([first, second]);
        final secondEntry = groups
            .expand((group) => group.entries)
            .firstWhere((entry) => entry.maintenance.id == 'b');
        final firstEntry = groups
            .expand((group) => group.entries)
            .firstWhere((entry) => entry.maintenance.id == 'a');

        expect(secondEntry.durationKm, 5000);
        expect(firstEntry.durationKm, isNull);
      },
    );

    test('does not mix durations across different types or vehicles', () {
      final oil = build(
        id: 'a',
        serviceDate: DateTime(2026, 1, 1),
        odometer: 10000,
      );
      final tire = build(
        id: 'b',
        serviceDate: DateTime(2026, 2, 1),
        odometer: 11000,
        type: 'Cambio de llanta',
      );

      final groups = MaintenanceHistoryGrouping.build([oil, tire]);
      final tireEntry = groups
          .expand((group) => group.entries)
          .firstWhere((entry) => entry.maintenance.id == 'b');

      expect(tireEntry.durationKm, isNull);
    });
  });

  group('MaintenanceHistoryGrouping.previousOf', () {
    test(
      'returns older records of the same type+vehicle, most recent first',
      () {
        final target = build(
          id: 'target',
          serviceDate: DateTime(2026, 8, 12),
          odometer: 18450,
        );
        final previous1 = build(
          id: 'p1',
          serviceDate: DateTime(2026, 3, 4),
          odometer: 10650,
        );
        final previous2 = build(
          id: 'p2',
          serviceDate: DateTime(2025, 9, 18),
          odometer: 2850,
        );
        final otherType = build(
          id: 'other',
          serviceDate: DateTime(2026, 4, 1),
          odometer: 12000,
          type: 'Cambio de llanta',
        );

        final entries = MaintenanceHistoryGrouping.previousOf(target, [
          target,
          previous1,
          previous2,
          otherType,
        ]);

        expect(entries.map((entry) => entry.maintenance.id), ['p1', 'p2']);
        expect(entries[0].durationKm, previous1.odometer - previous2.odometer);
        expect(entries[1].durationKm, isNull);
      },
    );
  });
}
