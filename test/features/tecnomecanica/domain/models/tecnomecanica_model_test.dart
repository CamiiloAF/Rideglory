import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_status.dart';

void main() {
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  TecnomecanicaModel rtmWithExpiry(DateTime expiryDate) => TecnomecanicaModel(
    id: 'rtm-1',
    vehicleId: 'vehicle-1',
    certificateNumber: 'CDA-001',
    cdaName: 'CDA Test',
    expiryDate: expiryDate,
  );

  group('TecnomecanicaModel — documentStatus via VehicleDocumentExpiry mixin', () {
    test('TC-rtm-01: documentStatus is valid when expiry is 31+ days away', () {
      final rtm = rtmWithExpiry(today().add(const Duration(days: 31)));
      expect(rtm.documentStatus, VehicleDocumentStatus.valid);
      expect(rtm.daysUntilExpiry, 31);
    });

    test(
      'TC-rtm-02: documentStatus is expiringSoon when expiry is exactly 30 days away',
      () {
        final rtm = rtmWithExpiry(today().add(const Duration(days: 30)));
        expect(rtm.documentStatus, VehicleDocumentStatus.expiringSoon);
        expect(rtm.daysUntilExpiry, 30);
      },
    );

    test(
      'TC-rtm-03: documentStatus is expiringSoon when expiry is 1 day away',
      () {
        final rtm = rtmWithExpiry(today().add(const Duration(days: 1)));
        expect(rtm.documentStatus, VehicleDocumentStatus.expiringSoon);
        expect(rtm.daysUntilExpiry, 1);
      },
    );

    test(
      'TC-rtm-04: documentStatus is expiringSoon when expiry is today (0 days)',
      () {
        final rtm = rtmWithExpiry(today());
        expect(rtm.documentStatus, VehicleDocumentStatus.expiringSoon);
        expect(rtm.daysUntilExpiry, 0);
      },
    );

    test(
      'TC-rtm-05: documentStatus is expired when expiry was yesterday',
      () {
        final rtm = rtmWithExpiry(today().subtract(const Duration(days: 1)));
        expect(rtm.documentStatus, VehicleDocumentStatus.expired);
        expect(rtm.daysUntilExpiry, -1);
      },
    );

    test(
      'TC-rtm-06: daysUntilExpiry is day-aligned regardless of time-of-day',
      () {
        final expiry = today().add(const Duration(days: 31));
        final expiryWithTime = DateTime(
          expiry.year,
          expiry.month,
          expiry.day,
          12,
          0,
          0,
        );
        final rtm = rtmWithExpiry(expiryWithTime);
        expect(rtm.daysUntilExpiry, 31);
        expect(rtm.documentStatus, VehicleDocumentStatus.valid);
      },
    );
  });

  group('TecnomecanicaModel — copyWith', () {
    test(
      'TC-rtm-07: copyWith returns updated model with unchanged fields intact',
      () {
        final original = TecnomecanicaModel(
          id: 'rtm-x',
          vehicleId: 'v-x',
          certificateNumber: 'CDA-100',
          cdaName: 'CDA Original',
          cdaCode: 'CODE-01',
          expiryDate: today().add(const Duration(days: 60)),
        );
        final updated = original.copyWith(cdaName: 'CDA Updated');
        expect(updated.id, 'rtm-x');
        expect(updated.vehicleId, 'v-x');
        expect(updated.certificateNumber, 'CDA-100');
        expect(updated.cdaName, 'CDA Updated');
        expect(updated.cdaCode, 'CODE-01');
      },
    );
  });

  group('TecnomecanicaModel — equality', () {
    test('TC-rtm-08: two models with same fields are equal', () {
      final expiry = today().add(const Duration(days: 30));
      final a = TecnomecanicaModel(
        id: 'id',
        vehicleId: 'vid',
        certificateNumber: 'CERT',
        cdaName: 'CDA',
        expiryDate: expiry,
      );
      final b = TecnomecanicaModel(
        id: 'id',
        vehicleId: 'vid',
        certificateNumber: 'CERT',
        cdaName: 'CDA',
        expiryDate: expiry,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('TC-rtm-09: models with different ids are not equal', () {
      final expiry = today().add(const Duration(days: 30));
      final a = TecnomecanicaModel(
        id: 'id-a',
        vehicleId: 'vid',
        certificateNumber: 'CERT',
        cdaName: 'CDA',
        expiryDate: expiry,
      );
      final b = TecnomecanicaModel(
        id: 'id-b',
        vehicleId: 'vid',
        certificateNumber: 'CERT',
        cdaName: 'CDA',
        expiryDate: expiry,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
