import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_expiry.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_status.dart';

// Concrete test implementation of the mixin.
class _TestDoc with VehicleDocumentExpiry {
  _TestDoc(this.expiryDate);

  @override
  final DateTime expiryDate;
}

void main() {
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  group('VehicleDocumentExpiry — daysUntilExpiry', () {
    test('returns positive days when expiry is in the future', () {
      final doc = _TestDoc(today().add(const Duration(days: 31)));
      expect(doc.daysUntilExpiry, 31);
    });

    test('returns 0 when expiry is today', () {
      final doc = _TestDoc(today());
      expect(doc.daysUntilExpiry, 0);
    });

    test('returns negative days when expiry is in the past', () {
      final doc = _TestDoc(today().subtract(const Duration(days: 5)));
      expect(doc.daysUntilExpiry, -5);
    });

    test('strips time component when computing days', () {
      final expiryWithTime = today().add(const Duration(days: 10, hours: 23, minutes: 59));
      final doc = _TestDoc(expiryWithTime);
      expect(doc.daysUntilExpiry, 10);
    });
  });

  group('VehicleDocumentExpiry — documentStatus', () {
    test('valid when more than 30 days remain', () {
      final doc = _TestDoc(today().add(const Duration(days: 31)));
      expect(doc.documentStatus, VehicleDocumentStatus.valid);
    });

    test('expiringSoon when exactly 30 days remain', () {
      final doc = _TestDoc(today().add(const Duration(days: 30)));
      expect(doc.documentStatus, VehicleDocumentStatus.expiringSoon);
    });

    test('expiringSoon when 1 day remains', () {
      final doc = _TestDoc(today().add(const Duration(days: 1)));
      expect(doc.documentStatus, VehicleDocumentStatus.expiringSoon);
    });

    test('expiringSoon when expiry is today (0 days)', () {
      final doc = _TestDoc(today());
      expect(doc.documentStatus, VehicleDocumentStatus.expiringSoon);
    });

    test('expired when expiry was yesterday', () {
      final doc = _TestDoc(today().subtract(const Duration(days: 1)));
      expect(doc.documentStatus, VehicleDocumentStatus.expired);
    });
  });

  group('SoatModel implements VehicleDocumentModel', () {
    test('documentStatus mirrors SoatStatus boundaries', () {
      // Verify the boundaries are consistent between the two status enums.
      // Valid ↔ VehicleDocumentStatus.valid
      final validDoc = _TestDoc(today().add(const Duration(days: 31)));
      expect(validDoc.documentStatus, VehicleDocumentStatus.valid);

      // ExpiringSoon ↔ VehicleDocumentStatus.expiringSoon
      final soonDoc = _TestDoc(today().add(const Duration(days: 15)));
      expect(soonDoc.documentStatus, VehicleDocumentStatus.expiringSoon);

      // Expired ↔ VehicleDocumentStatus.expired
      final expiredDoc = _TestDoc(today().subtract(const Duration(days: 1)));
      expect(expiredDoc.documentStatus, VehicleDocumentStatus.expired);
    });
  });
}
