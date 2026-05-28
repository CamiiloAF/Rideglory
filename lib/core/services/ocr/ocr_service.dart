import 'dart:io';

import 'ocr_result.dart';

/// On-device OCR contract. Implementations must not perform any network I/O —
/// text recognition happens entirely on the device for privacy.
abstract class OcrService {
  Future<OcrResult> recognizeText(File image);
}
