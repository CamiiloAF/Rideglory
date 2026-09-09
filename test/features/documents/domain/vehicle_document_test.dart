import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/documents/domain/models/vehicle_document.dart';

void main() {
  final now = DateTime(2026, 9, 9);

  VehicleDocument documentExpiringIn(int days) {
    return VehicleDocument(
      id: 'doc-1',
      vehicleId: 'vehicle-1',
      kind: DocumentKind.soat,
      expiryDate: now.add(Duration(days: days)),
      reminderEnabled: true,
    );
  }

  group('VehicleDocument.statusAt', () {
    test('is valid when more than 30 days remain', () {
      expect(documentExpiringIn(45).statusAt(now), DocumentStatus.valid);
    });

    test('is expiringSoon within the 30-day window', () {
      expect(documentExpiringIn(30).statusAt(now), DocumentStatus.expiringSoon);
      expect(documentExpiringIn(1).statusAt(now), DocumentStatus.expiringSoon);
    });

    test('is expired once the expiry date has passed', () {
      expect(documentExpiringIn(-1).statusAt(now), DocumentStatus.expired);
    });
  });
}
