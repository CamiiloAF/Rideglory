import 'package:injectable/injectable.dart';

import '../../../../core/services/ocr/ocr_result.dart';
import '../../data/parser/soat_parser.dart';
import '../models/soat_extraction.dart';

/// Pure use case: maps an [OcrResult] to a [SoatExtraction].
///
/// Holds no I/O so it can be tested directly with text fixtures.
@injectable
class ParseSoatTextUseCase {
  const ParseSoatTextUseCase(this._parser);

  final SoatParser _parser;

  SoatExtraction call(OcrResult ocr) => _parser.parse(ocr);
}
