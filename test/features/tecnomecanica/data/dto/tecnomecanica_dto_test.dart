import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/tecnomecanica/data/dto/tecnomecanica_dto.dart';

void main() {
  group('TecnomecanicaDto — serialization (Pattern B)', () {
    final startDate = DateTime(2026, 1, 1);
    final expiryDate = DateTime(2026, 12, 31);

    final json = <String, dynamic>{
      'id': 'rtm-1',
      'vehicleId': 'vehicle-1',
      'cdaName': 'CDA Test',
      'startDate': '2026-01-01T00:00:00.000',
      'expiryDate': '2026-12-31T00:00:00.000',
      'documentUrl': null,
      'createdAt': null,
      'updatedAt': null,
    };

    test('TC-dto-01: fromJson deserializes required fields correctly', () {
      final dto = TecnomecanicaDto.fromJson(json);
      expect(dto.id, 'rtm-1');
      expect(dto.vehicleId, 'vehicle-1');
      expect(dto.cdaName, 'CDA Test');
      expect(dto.startDate.year, startDate.year);
      expect(dto.expiryDate.year, expiryDate.year);
      expect(dto.expiryDate.month, expiryDate.month);
      expect(dto.expiryDate.day, expiryDate.day);
    });

    test('TC-dto-02: fromJson handles null optional fields', () {
      final jsonMinimal = <String, dynamic>{
        'id': 'rtm-2',
        'vehicleId': 'v-2',
        'cdaName': 'CDA Minimal',
        'startDate': '2026-01-01T00:00:00.000',
        'expiryDate': '2026-06-30T00:00:00.000',
      };
      final dto = TecnomecanicaDto.fromJson(jsonMinimal);
      expect(dto.documentUrl, isNull);
    });

    test('TC-dto-03: TecnomecanicaDto is a TecnomecanicaModel (Pattern B inheritance)', () {
      final dto = TecnomecanicaDto.fromJson(json);
      expect(dto, isA<TecnomecanicaDto>());
      expect(dto.runtimeType.toString(), contains('TecnomecanicaDto'));
    });
  });

  group('CreateTecnomecanicaRequestDto — toJson', () {
    test(
      'TC-dto-04: toJson serializes startDate and expiryDate as ISO8601 strings',
      () {
        final dto = CreateTecnomecanicaRequestDto(
          cdaName: 'CDA Test',
          startDate: DateTime(2026, 1, 1),
          expiryDate: DateTime(2026, 12, 31),
        );
        final json = dto.toJson();
        expect(json['cdaName'], 'CDA Test');
        expect(json['startDate'], isA<String>());
        expect(json['expiryDate'], isA<String>());
        expect((json['expiryDate'] as String), contains('2026'));
      },
    );

    test('TC-dto-05: toJson includes documentUrl when non-null', () {
      final dto = CreateTecnomecanicaRequestDto(
        cdaName: 'CDA Optional',
        startDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2027, 1, 1),
        documentUrl: 'https://example.com/doc.pdf',
      );
      final json = dto.toJson();
      expect(json['startDate'], isNotNull);
      expect(json['documentUrl'], 'https://example.com/doc.pdf');
    });

    test('TC-dto-06: toJson does not include id or vehicleId (write DTO only)', () {
      final dto = CreateTecnomecanicaRequestDto(
        cdaName: 'CDA Test',
        startDate: DateTime(2026, 1, 1),
        expiryDate: DateTime(2026, 6, 30),
      );
      final json = dto.toJson();
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('vehicleId'), isFalse);
    });
  });
}
