import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';

void main() {
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  SoatModel soatWithExpiry(DateTime expiryDate) =>
      SoatModel(id: 'soat-1', vehicleId: 'vehicle-1', expiryDate: expiryDate);

  group('SoatModel — status badge logic (US-2-6)', () {
    // TC-2-20: SOAT with expiry > 30 days from today → valid
    test('TC-2-20: status is valid when expiry is 31+ days away', () {
      final soat = soatWithExpiry(today().add(const Duration(days: 31)));
      expect(soat.status, SoatStatus.valid);
      expect(soat.daysUntilExpiry, 31);
    });

    // TC-2-21: SOAT with expiry exactly 30 days from today → expiringSoon
    test(
      'TC-2-21: status is expiringSoon when expiry is exactly 30 days away',
      () {
        final soat = soatWithExpiry(today().add(const Duration(days: 30)));
        expect(soat.status, SoatStatus.expiringSoon);
        expect(soat.daysUntilExpiry, 30);
      },
    );

    // TC-2-22: SOAT with expiry 1 day from today → expiringSoon
    test('TC-2-22: status is expiringSoon when expiry is 1 day away', () {
      final soat = soatWithExpiry(today().add(const Duration(days: 1)));
      expect(soat.status, SoatStatus.expiringSoon);
      expect(soat.daysUntilExpiry, 1);
    });

    // TC-2-23: SOAT with expiry today (0 days) → expiringSoon
    test('TC-2-23: status is expiringSoon when expiry is today (0 days)', () {
      final soat = soatWithExpiry(today());
      expect(soat.status, SoatStatus.expiringSoon);
      expect(soat.daysUntilExpiry, 0);
    });

    // TC-2-24: SOAT with expiry 1 day ago → expired
    test('TC-2-24: status is expired when expiry was yesterday', () {
      final soat = soatWithExpiry(today().subtract(const Duration(days: 1)));
      expect(soat.status, SoatStatus.expired);
      expect(soat.daysUntilExpiry, -1);
    });

    // TC-2-25: daysUntilExpiry is day-aligned (no time component leakage)
    test('TC-2-25: daysUntilExpiry is day-aligned regardless of time-of-day', () {
      // Expiry date set with noon time — should still read as 31 days from today
      final expiry = today().add(const Duration(days: 31));
      final expiryWithTime = DateTime(
        expiry.year,
        expiry.month,
        expiry.day,
        12,
        0,
        0,
      );
      final soat = soatWithExpiry(expiryWithTime);
      expect(soat.daysUntilExpiry, 31);
      expect(soat.status, SoatStatus.valid);
    });

    // TC-2-26: copyWith preserves all unchanged fields
    test(
      'TC-2-26: copyWith returns updated model with unchanged fields intact',
      () {
        final original = SoatModel(
          id: 'soat-x',
          vehicleId: 'v-x',
          policyNumber: 'POL-123',
          insurer: 'Sura',
          expiryDate: today().add(const Duration(days: 60)),
        );
        final updated = original.copyWith(policyNumber: 'POL-999');
        expect(updated.id, 'soat-x');
        expect(updated.vehicleId, 'v-x');
        expect(updated.policyNumber, 'POL-999');
        expect(updated.insurer, 'Sura');
      },
    );
  });
}
