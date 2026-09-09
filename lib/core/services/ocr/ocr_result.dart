import 'package:flutter/foundation.dart';

/// A single recognized text block with its position in the source image.
///
/// The [boundingBox] is expressed in image pixel coordinates as
/// `[left, top, right, bottom]`.
@immutable
class OcrBlock {
  const OcrBlock({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => (right - left).abs();

  double get height => (bottom - top).abs();

  double get area => width * height;

  /// Vertical center of the block, useful to pair labels with values that sit
  /// on the same line of the document.
  double get centerY => (top + bottom) / 2;

  double get centerX => (left + right) / 2;
}

/// Pure-Dart result of an OCR pass over an image.
///
/// Contains the flattened [fullText] plus the individual [blocks] so the parser
/// can reason about layout (label/value proximity, logo area, etc.).
@immutable
class OcrResult {
  const OcrResult({required this.fullText, required this.blocks});

  const OcrResult.empty() : fullText = '', blocks = const [];

  final String fullText;
  final List<OcrBlock> blocks;

  bool get isEmpty => fullText.trim().isEmpty;
}
