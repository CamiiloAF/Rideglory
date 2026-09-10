import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/garage/domain/models/vehicle_document_alert.dart';

void main() {
  final now = DateTime(2026, 9, 9);

  group('VehicleDocumentAlert.mostUrgent', () {
    test('returns null when there are no documents', () {
      expect(VehicleDocumentAlert.mostUrgent([], now), isNull);
    });

    test(
      'returns null when every document is valid beyond the 30-day window',
      () {
        final documents = [
          (
            kind: DocumentAlertKind.soat,
            expiryDate: now.add(const Duration(days: 90)),
          ),
        ];
        expect(VehicleDocumentAlert.mostUrgent(documents, now), isNull);
      },
    );

    test('flags a document expiring within 30 days as a warning', () {
      final documents = [
        (
          kind: DocumentAlertKind.rtm,
          expiryDate: now.add(const Duration(days: 12)),
        ),
      ];
      final alert = VehicleDocumentAlert.mostUrgent(documents, now)!;
      expect(alert.severity, DocumentAlertSeverity.warning);
      expect(alert.kind, DocumentAlertKind.rtm);
      expect(alert.daysUntilExpiry, 12);
    });

    test(
      'flags an expired document as critical, even over a soon-to-expire one',
      () {
        final documents = [
          (
            kind: DocumentAlertKind.rtm,
            expiryDate: now.add(const Duration(days: 5)),
          ),
          (
            kind: DocumentAlertKind.soat,
            expiryDate: now.subtract(const Duration(days: 3)),
          ),
        ];
        final alert = VehicleDocumentAlert.mostUrgent(documents, now)!;
        expect(alert.severity, DocumentAlertSeverity.critical);
        expect(alert.kind, DocumentAlertKind.soat);
      },
    );

    test(
      'picks the soonest-to-expire document when several are within the window',
      () {
        final documents = [
          (
            kind: DocumentAlertKind.rtm,
            expiryDate: now.add(const Duration(days: 20)),
          ),
          (
            kind: DocumentAlertKind.soat,
            expiryDate: now.add(const Duration(days: 5)),
          ),
        ];
        final alert = VehicleDocumentAlert.mostUrgent(documents, now)!;
        expect(alert.kind, DocumentAlertKind.soat);
        expect(alert.daysUntilExpiry, 5);
      },
    );
  });
}
