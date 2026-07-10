import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/ocr/ocr_result.dart';
import 'package:rideglory/features/soat/data/parser/soat_parser.dart';
import 'package:rideglory/features/soat/domain/models/soat_extraction.dart';
import 'package:rideglory/features/soat/domain/usecases/parse_soat_text_usecase.dart';

class MockSoatParser extends Mock implements SoatParser {}

void main() {
  late MockSoatParser mockParser;
  late ParseSoatTextUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const OcrResult.empty());
  });

  setUp(() {
    mockParser = MockSoatParser();
    useCase = ParseSoatTextUseCase(mockParser);
  });

  test('camino feliz — delega el OcrResult en el parser y retorna la extracción', () {
    const ocrResult = OcrResult(
      fullText: 'SOAT SURA póliza 123456789',
      blocks: [],
    );
    const extraction = SoatExtraction(
      policyNumber: '123456789',
      insurer: 'SURA',
      policyNumberConfidence: OcrFieldConfidence.high,
      insurerConfidence: OcrFieldConfidence.high,
    );
    when(() => mockParser.parse(ocrResult)).thenReturn(extraction);

    final result = useCase(ocrResult);

    expect(result, extraction);
    verify(() => mockParser.parse(ocrResult)).called(1);
  });

  test('camino de error — texto vacío produce una extracción vacía sin prellenado', () {
    const ocrResult = OcrResult.empty();
    const extraction = SoatExtraction.empty();
    when(() => mockParser.parse(ocrResult)).thenReturn(extraction);

    final result = useCase(ocrResult);

    expect(result.shouldPrefill, isFalse);
    expect(result.policyNumber, isNull);
    verify(() => mockParser.parse(ocrResult)).called(1);
  });
}
