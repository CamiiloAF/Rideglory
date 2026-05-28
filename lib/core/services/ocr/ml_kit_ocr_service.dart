import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:injectable/injectable.dart';

import 'ocr_result.dart';
import 'ocr_service.dart';

/// [OcrService] backed by ML Kit's on-device Latin text recognizer.
@Injectable(as: OcrService)
class MlKitOcrService implements OcrService {
  MlKitOcrService();

  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  @override
  Future<OcrResult> recognizeText(File image) async {
    final inputImage = InputImage.fromFile(image);
    final recognized = await _recognizer.processImage(inputImage);

    final blocks = <OcrBlock>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final rect = line.boundingBox;
        blocks.add(
          OcrBlock(
            text: line.text,
            left: rect.left.toDouble(),
            top: rect.top.toDouble(),
            right: rect.right.toDouble(),
            bottom: rect.bottom.toDouble(),
          ),
        );
      }
    }

    return OcrResult(fullText: recognized.text, blocks: blocks);
  }
}
