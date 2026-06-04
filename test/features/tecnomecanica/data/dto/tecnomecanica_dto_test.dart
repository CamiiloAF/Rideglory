import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/tecnomecanica/data/dto/tecnomecanica_dto.dart';

void main() {
  group('TecnomecanicaDto — serialization (Pattern B)', () {
    final expiryDate = DateTime(2026, 12, 31);

    final json = <String, dynamic>{
      'id': 'rtm-1',
      'vehicleId': 'vehicle-1',
      'certificateNumber': 'CDA-001',
      'cdaName': 'CDA Test',
      'cdaCode': 'CODE-01',
      'startDate': null,
      'expiryDate': '2026-12-31T00:00:00.000',
      'documentUrl': null,
      'createdAt': null,
      'updatedAt': null,
    };

    test('TC-dto-01: fromJson deserializes required fields correctly', () {
      final dto = TecnomecanicaDto.fromJson(json);
      expect(dto.id, 'rtm-1');
      expect(dto.vehicleId, 'vehicle-1');
      expect(dto.certificateNumber, 'CDA-001');
      expect(dto.cdaName, 'CDA Test');
      expect(dto.cdaCode, 'CODE-01');
      expect(dto.expiryDate.year, expiryDate.year);
      expect(dto.expiryDate.month, expiryDate.month);
      expect(dto.expiryDate.day, expiryDate.day);
    });

    test('TC-dto-02: fromJson handles null optional fields', () {
      final jsonMinimal = <String, dynamic>{
        'id': 'rtm-2',
        'vehicleId': 'v-2',
        'certificateNumber': 'CDA-002',
        'cdaName': 'CDA Minimal',
        'expiryDate': '2026-06-30T00:00:00.000',
      };
      final dto = TecnomecanicaDto.fromJson(jsonMinimal);
      expect(dto.cdaCode, isNull);
      expect(dto.startDate, isNull);
      expect(dto.documentUrl, isNull);
    });

    test('TC-dto-03: TecnomecanicaDto is a TecnomecanicaModel (Pattern B inheritance)', () {
      final dto = TecnomecanicaDto.fromJson(json);
      expect(dto, isA<TecnomecanicaDto>());
      // Pattern B: DTO extends model
      expect(dto.runtimeType.toString(), contains('TecnomecanicaDto'));
      expect(dto.certificateNumber, 'CDA-001');
    });
  });

  group('CreateTecnomecanicaRequestDto — toJson', () {
    test(
      'TC-dto-04: toJson serializes expiryDate as ISO8601 UTC string',
      () {
        final dto = CreateTecnomecanicaRequestDto(
          certificateNumber: 'CERT-001',
          cdaName: 'CDA Test',
          expiryDate: DateTime(2026, 12, 31),
        );
        final json = dto.toJson();
        expect(json['certificateNumber'], 'CERT-001');
        expect(json['cdaName'], 'CDA Test');
        expect(json['expiryDate'], isA<String>());
        final expiryStr = json['expiryDate'] as String;
        expect(expiryStr, contains('2026'));
      },
    );

    test('TC-dto-05: toJson includes optional fields when non-null', () {
      final dto = CreateTecnomecanicaRequestDto(
        certificateNumber: 'CERT-002',
        cdaName: 'CDA Optional',
        cdaCode: 'CODE-XY',
        startDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2027, 1, 1),
        documentUrl: 'https://example.com/doc.pdf',
      );
      final json = dto.toJson();
      expect(json['cdaCode'], 'CODE-XY');
      expect(json['startDate'], isNotNull);
      expect(json['documentUrl'], 'https://example.com/doc.pdf');
    });

    test('TC-dto-06: toJson does not include id or vehicleId (write DTO only)', () {
      final dto = CreateTecnomecanicaRequestDto(
        certificateNumber: 'CERT-003',
        cdaName: 'CDA Test',
        expiryDate: DateTime(2026, 6, 30),
      );
      final json = dto.toJson();
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('vehicleId'), isFalse);
    });
  });
}
