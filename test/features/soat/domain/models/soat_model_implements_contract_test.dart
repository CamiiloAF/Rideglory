import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_model.dart';

void main() {
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  SoatModel soatWithExpiry(DateTime expiryDate) =>
      SoatModel(id: 'soat-1', vehicleId: 'vehicle-1', expiryDate: expiryDate);

  group('SoatModel implements VehicleDocumentModel contract (ADR-A)', () {
    test('SoatModel is a VehicleDocumentModel', () {
      final soat = soatWithExpiry(today().add(const Duration(days: 40)));
      expect(soat, isA<VehicleDocumentModel>());
    });

    test('id and vehicleId are accessible via contract', () {
      final soat = soatWithExpiry(today().add(const Duration(days: 40)));
      final VehicleDocumentModel doc = soat;
      expect(doc.id, 'soat-1');
      expect(doc.vehicleId, 'vehicle-1');
    });

    test('documentStatus is valid when >30 days remain', () {
      final soat = soatWithExpiry(today().add(const Duration(days: 40)));
      expect(soat.documentStatus, VehicleDocumentStatus.valid);
    });

    test('documentStatus is expiringSoon within 30 days', () {
      final soat = soatWithExpiry(today().add(const Duration(days: 15)));
      expect(soat.documentStatus, VehicleDocumentStatus.expiringSoon);
    });

    test('documentStatus is expired when past', () {
      final soat = soatWithExpiry(today().subtract(const Duration(days: 1)));
      expect(soat.documentStatus, VehicleDocumentStatus.expired);
    });

    test('daysUntilExpiry is consistent with SoatStatus', () {
      final soat = soatWithExpiry(today().add(const Duration(days: 31)));
      // Both APIs should report the same number.
      expect(soat.daysUntilExpiry, 31);
      expect(soat.status, SoatStatus.valid);
      expect(soat.documentStatus, VehicleDocumentStatus.valid);
    });
  });
}
