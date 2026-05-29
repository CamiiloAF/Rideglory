import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/core/services/ocr/ocr_result.dart';
import 'package:rideglory/features/soat/data/parser/soat_parser.dart';
import 'package:rideglory/features/soat/domain/models/soat_extraction.dart';

/// Builds an [OcrResult] from a multi-line fixture, laying each line out on its
/// own horizontal band so the parser's bounding-box heuristics behave like a
/// real document scan.
OcrResult fixture(String text) {
  final lines = text.trim().split('\n');
  final blocks = <OcrBlock>[];
  var top = 0.0;
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) {
      top += 40;
      continue;
    }
    blocks.add(
      OcrBlock(
        text: line,
        left: 0,
        top: top,
        right: line.length * 10,
        bottom: top + 30,
      ),
    );
    top += 40;
  }
  return OcrResult(fullText: lines.join('\n'), blocks: blocks);
}

void main() {
  const parser = SoatParser();

  group('SoatParser — aseguradoras (matching por nombre + variantes)', () {
    test('SURA (variante "Suramericana")', () {
      final result = parser.parse(
        fixture('''
SEGUROS SURAMERICANA S.A.
SOAT
N° Póliza 0123456789
Vigencia desde 15/01/2026
Hasta 15/01/2027
'''),
      );
      expect(result.insurer, 'SURA');
      expect(result.insurerConfidence, OcrFieldConfidence.high);
      expect(result.policyNumber, '0123456789');
      expect(result.startDate, DateTime(2026, 1, 15));
      expect(result.expiryDate, DateTime(2027, 1, 15));
      expect(result.shouldPrefill, isTrue);
    });

    test('Seguros Bolívar', () {
      final result = parser.parse(
        fixture('''
SEGUROS BOLIVAR
Numero de poliza AB12345678
Desde 01/03/2026
Vence 01/03/2027
'''),
      );
      expect(result.insurer, 'Seguros Bolívar');
      expect(result.policyNumber, 'AB12345678');
      expect(result.startDate, DateTime(2026, 3, 1));
      expect(result.expiryDate, DateTime(2027, 3, 1));
    });

    test('Seguros del Estado', () {
      final result = parser.parse(
        fixture('''
SEGUROS DEL ESTADO S.A.
Poliza 998877665544
Vigencia desde 10 ene 2026
Hasta 10 ene 2027
'''),
      );
      expect(result.insurer, 'Seguros del Estado');
      expect(result.policyNumber, '998877665544');
      expect(result.startDate, DateTime(2026, 1, 10));
      expect(result.expiryDate, DateTime(2027, 1, 10));
    });

    test('Seguros del Estado — póliza en fila separada, ignora celular', () {
      // Layout real (tabla): el valor de la póliza va debajo del encabezado y
      // el celular del tomador (10 dígitos, inicia en 3) no debe confundirse.
      final result = parser.parse(
        fixture('''
SEGUROS DEL ESTADO S.A.
No. DE PÓLIZA.
15683400107070
TELEFONO DEL TOMADOR
3146432187
No. DE DOCUMENTO DEL TOMADOR
1004681124
Vigencia desde 29/11/2024
Hasta 28/11/2025
'''),
      );
      expect(result.insurer, 'Seguros del Estado');
      expect(result.policyNumber, '15683400107070');
      expect(result.startDate, DateTime(2024, 11, 29));
      expect(result.expiryDate, DateTime(2025, 11, 28));
    });

    test('AXA Colpatria', () {
      final result = parser.parse(
        fixture('''
AXA COLPATRIA SEGUROS
No. Poliza 456789012345
Vigencia desde 2026-02-20
Hasta 2027-02-20
'''),
      );
      expect(result.insurer, 'AXA Colpatria');
      expect(result.policyNumber, '456789012345');
      expect(result.startDate, DateTime(2026, 2, 20));
      expect(result.expiryDate, DateTime(2027, 2, 20));
    });

    test('Seguros Mundial', () {
      final result = parser.parse(
        fixture('''
SEGUROS MUNDIAL
Poliza MUN987654321
Desde 05/06/2026
Hasta 05/06/2027
'''),
      );
      expect(result.insurer, 'Seguros Mundial');
      expect(result.policyNumber, 'MUN987654321');
      expect(result.startDate, DateTime(2026, 6, 5));
      expect(result.expiryDate, DateTime(2027, 6, 5));
    });

    test('La Previsora (regex genérica de póliza)', () {
      final result = parser.parse(
        fixture('''
LA PREVISORA S.A. COMPANIA DE SEGUROS
Poliza 112233445566
Vigencia desde 12/12/2026
Hasta 12/12/2027
'''),
      );
      expect(result.insurer, 'La Previsora');
      expect(result.policyNumber, '112233445566');
      expect(result.startDate, DateTime(2026, 12, 12));
      expect(result.expiryDate, DateTime(2027, 12, 12));
    });

    test('Liberty Seguros', () {
      final result = parser.parse(
        fixture('''
LIBERTY SEGUROS S.A.
Numero de poliza 778899001122
Desde 03/04/2026
Hasta 03/04/2027
'''),
      );
      expect(result.insurer, 'Liberty Seguros');
      expect(result.startDate, DateTime(2026, 4, 3));
      expect(result.expiryDate, DateTime(2027, 4, 3));
    });

    test('Mapfre', () {
      final result = parser.parse(
        fixture('''
MAPFRE SEGUROS GENERALES DE COLOMBIA
Poliza 5544332211009
Vigencia desde 18/07/2026
Hasta 18/07/2027
'''),
      );
      expect(result.insurer, 'Mapfre');
      expect(result.startDate, DateTime(2026, 7, 18));
      expect(result.expiryDate, DateTime(2027, 7, 18));
    });

    test('La Equidad', () {
      final result = parser.parse(
        fixture('''
LA EQUIDAD SEGUROS
Poliza 332211009988
Desde 22/08/2026
Hasta 22/08/2027
'''),
      );
      expect(result.insurer, 'La Equidad');
      expect(result.startDate, DateTime(2026, 8, 22));
      expect(result.expiryDate, DateTime(2027, 8, 22));
    });

    test('Aseguradora Solidaria (variante "Solidaria")', () {
      final result = parser.parse(
        fixture('''
ASEGURADORA SOLIDARIA DE COLOMBIA
Poliza 909090909090
Vigencia desde 09/09/2026
Hasta 09/09/2027
'''),
      );
      expect(result.insurer, 'Aseguradora Solidaria');
      expect(result.startDate, DateTime(2026, 9, 9));
      expect(result.expiryDate, DateTime(2027, 9, 9));
    });
  });

  group('SoatParser — casos negativos', () {
    test('texto vacío no extrae nada', () {
      final result = parser.parse(const OcrResult.empty());
      expect(result.insurer, isNull);
      expect(result.policyNumber, isNull);
      expect(result.startDate, isNull);
      expect(result.shouldPrefill, isFalse);
    });

    test('texto irrelevante (factura) no produce prefill', () {
      final result = parser.parse(
        fixture('''
FACTURA DE VENTA
Gracias por su compra
Total a pagar 50000
'''),
      );
      expect(result.insurer, isNull);
      expect(result.startDate, isNull);
      expect(result.shouldPrefill, isFalse);
    });

    test('fechas que NO suman ~1 año son descartadas (validación dura)', () {
      final result = parser.parse(
        fixture('''
SEGUROS SURA
Poliza 0123456789
Vigencia desde 15/01/2026
Hasta 15/06/2026
'''),
      );
      // Insurer + policy detected, but dates fail the 360–370 day rule.
      expect(result.startDate, isNull);
      expect(result.expiryDate, isNull);
      expect(result.startDateConfidence, OcrFieldConfidence.low);
      // Only 2 high-confidence fields (insurer + policy) → still prefilled,
      // but dates explicitly dropped and the failure is flagged.
      expect(result.insurer, 'SURA');
      expect(result.policyNumber, '0123456789');
      expect(result.datesFailedValidation, isTrue);
    });

    test('fechas fuera de rango con resto ilegible → no prefill + flag', () {
      final result = parser.parse(
        fixture('''
Documento sin aseguradora ni poliza legible
Vigencia desde 15/01/2026
Hasta 15/06/2026
'''),
      );
      // No prefillable fields, but the two dates failed the span rule.
      expect(result.shouldPrefill, isFalse);
      expect(result.startDate, isNull);
      expect(result.expiryDate, isNull);
      expect(result.datesFailedValidation, isTrue);
    });

    test('fechas válidas no marcan datesFailedValidation', () {
      final result = parser.parse(
        fixture('''
SEGUROS SURA
Poliza 0123456789
Vigencia desde 15/01/2026
Hasta 15/01/2027
'''),
      );
      expect(result.datesFailedValidation, isFalse);
    });

    test('solo un campo de alta confianza NO se prellena', () {
      final result = parser.parse(
        fixture('''
SEGUROS SURA
Documento sin fechas legibles ni poliza
'''),
      );
      expect(result.highConfidenceCount, lessThan(2));
      expect(result.shouldPrefill, isFalse);
    });

    test('dos fechas sin label: menor=inicio, mayor=vencimiento (medium)', () {
      final result = parser.parse(
        fixture('''
SEGUROS SURA
Poliza 0123456789
15/01/2026
15/01/2027
'''),
      );
      expect(result.startDate, DateTime(2026, 1, 15));
      expect(result.expiryDate, DateTime(2027, 1, 15));
      expect(result.startDateConfidence, OcrFieldConfidence.medium);
    });
  });

  group('SoatExtraction — reglas de prefill', () {
    test('umbral: 2+ campos high → shouldPrefill', () {
      const extraction = SoatExtraction(
        insurer: 'SURA',
        insurerConfidence: OcrFieldConfidence.high,
        policyNumber: '0123456789',
        policyNumberConfidence: OcrFieldConfidence.high,
      );
      expect(extraction.shouldPrefill, isTrue);
      expect(extraction.highConfidenceCount, 2);
    });

    test('isFieldAutofilled ignora campos low', () {
      const extraction = SoatExtraction(
        insurer: 'SURA',
        insurerConfidence: OcrFieldConfidence.high,
        policyNumber: '123',
        policyNumberConfidence: OcrFieldConfidence.low,
      );
      expect(extraction.isFieldAutofilled(SoatField.insurer), isTrue);
      expect(extraction.isFieldAutofilled(SoatField.policyNumber), isFalse);
    });
  });
}
