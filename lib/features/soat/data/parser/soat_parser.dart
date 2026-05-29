import 'package:injectable/injectable.dart';

import '../../../../core/services/ocr/ocr_result.dart';
import '../../domain/models/soat_extraction.dart';
import 'soat_insurer_rules.dart';

/// Pure-Dart parser that maps recognized SOAT text into a [SoatExtraction].
///
/// Stateless and side-effect free so it is trivially unit-testable with text
/// fixtures (no ML Kit, no I/O).
@injectable
class SoatParser {
  const SoatParser();

  static const int _minPolicyLength = 8;
  static const int _maxPolicyLength = 15;

  static const _spanishMonths = <String, int>{
    'ene': 1,
    'feb': 2,
    'mar': 3,
    'abr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'ago': 8,
    'sep': 9,
    'set': 9,
    'oct': 10,
    'nov': 11,
    'dic': 12,
  };

  static final RegExp _genericPolicyPattern = RegExp(
    r'\b([A-Z]{0,4}[-]?\d[\dA-Z-]{6,14})\b',
  );

  SoatExtraction parse(OcrResult ocr) {
    if (ocr.isEmpty) return const SoatExtraction.empty();

    final normalizedText = _normalize(ocr.fullText);

    final insurerResult = _detectInsurer(ocr, normalizedText);
    final policyResult = _detectPolicyNumber(
      ocr,
      normalizedText,
      insurerResult.rule,
    );
    final datesResult = _detectDates(ocr, normalizedText);

    return SoatExtraction(
      insurer: insurerResult.value,
      insurerConfidence: insurerResult.confidence,
      policyNumber: policyResult.value,
      policyNumberConfidence: policyResult.confidence,
      startDate: datesResult.startDate,
      startDateConfidence: datesResult.startConfidence,
      expiryDate: datesResult.expiryDate,
      expiryDateConfidence: datesResult.expiryConfidence,
      datesFailedValidation: datesResult.failedValidation,
    );
  }

  // ── Insurer ───────────────────────────────────────────────────────────────

  _InsurerResult _detectInsurer(OcrResult ocr, String normalizedText) {
    final matches = <SoatInsurerRule>[];
    for (final rule in kSoatInsurerRules) {
      if (rule.aliases.any(normalizedText.contains)) {
        matches.add(rule);
      }
    }

    if (matches.isEmpty) {
      return const _InsurerResult(null, null, OcrFieldConfidence.low);
    }
    if (matches.length == 1) {
      return _InsurerResult(
        matches.first.canonicalName,
        matches.first,
        OcrFieldConfidence.high,
      );
    }

    // Tie-break: prefer the insurer whose alias appears in the largest block
    // located in the top quarter of the document (typically the logo).
    final maxTop = ocr.blocks.fold<double>(
      0,
      (acc, block) => block.bottom > acc ? block.bottom : acc,
    );
    final topQuarterLimit = maxTop / 4;

    SoatInsurerRule? winner;
    var winnerArea = -1.0;
    for (final rule in matches) {
      for (final block in ocr.blocks) {
        final blockText = _normalize(block.text);
        final aliasHit = rule.aliases.any(blockText.contains);
        if (!aliasHit) continue;
        final inTopQuarter = block.top <= topQuarterLimit;
        final weightedArea = inTopQuarter ? block.area * 2 : block.area;
        if (weightedArea > winnerArea) {
          winnerArea = weightedArea;
          winner = rule;
        }
      }
    }

    winner ??= matches.first;
    return _InsurerResult(
      winner.canonicalName,
      winner,
      OcrFieldConfidence.high,
    );
  }

  // ── Policy number ───────────────────────────────────────────────────────

  _FieldResult<String> _detectPolicyNumber(
    OcrResult ocr,
    String normalizedText,
    SoatInsurerRule? insurer,
  ) {
    // Strategy 1: line carrying a "póliza" label → nearest alphanumeric token.
    final labelMatch = _policyFromLabel(ocr);
    if (labelMatch != null) {
      return _FieldResult(labelMatch, OcrFieldConfidence.high);
    }

    // Strategy 2: insurer-specific regex when known.
    if (insurer != null) {
      final pattern = kInsurerPolicyPatterns[insurer.canonicalName];
      if (pattern != null) {
        final match = pattern.firstMatch(ocr.fullText.toUpperCase());
        final value = match?.group(1);
        if (value != null && _isPlausiblePolicy(value)) {
          return _FieldResult(value, OcrFieldConfidence.medium);
        }
      }
    }

    // Strategy 3: generic regex over the full text. Phone numbers and dates
    // share the SOAT with the policy, so skip those and prefer the candidate
    // with the most digits (policy numbers are the longest numeric token).
    String? best;
    var bestDigits = 0;
    for (final match in _genericPolicyPattern.allMatches(
      ocr.fullText.toUpperCase(),
    )) {
      final value = match.group(1);
      if (value == null || !_isPlausiblePolicy(value) || !_hasDigit(value)) {
        continue;
      }
      if (_looksLikePhone(value) || _looksLikeDate(value)) continue;
      final digits = _digitCount(value);
      if (digits > bestDigits) {
        bestDigits = digits;
        best = value;
      }
    }
    if (best != null) return _FieldResult(best, OcrFieldConfidence.medium);

    return const _FieldResult(null, OcrFieldConfidence.low);
  }

  /// Colombian mobile numbers are exactly 10 digits starting with 3; they must
  /// never be mistaken for a policy number.
  bool _looksLikePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10 && digits.startsWith('3');
  }

  bool _looksLikeDate(String value) =>
      RegExp(r'^\d{1,4}[-/.]\d{1,2}[-/.]\d{1,4}$').hasMatch(value);

  int _digitCount(String value) => RegExp(r'\d').allMatches(value).length;

  String? _policyFromLabel(OcrResult ocr) {
    const labels = ['poliza', 'n poliza', 'no poliza', 'numero de poliza'];
    for (final block in ocr.blocks) {
      final normalized = _normalize(block.text);
      if (!labels.any(normalized.contains)) continue;

      // Same-line token after the label.
      final inline = _firstPolicyToken(block.text);
      if (inline != null) return inline;

      // Token in the closest block on the same horizontal line.
      final neighbor = _closestBlockOnSameLine(ocr, block);
      if (neighbor != null) {
        final token = _firstPolicyToken(neighbor.text);
        if (token != null) return token;
      }

      // Table layout (e.g. Seguros del Estado): the value sits in the block
      // right below the header label, in the same column.
      final below = _closestBlockBelow(ocr, block);
      if (below != null) {
        final token = _firstPolicyToken(below.text);
        if (token != null) return token;
      }
    }
    return null;
  }

  OcrBlock? _closestBlockBelow(OcrResult ocr, OcrBlock label) {
    OcrBlock? closest;
    var bestDistance = double.infinity;
    for (final block in ocr.blocks) {
      if (identical(block, label)) continue;
      final isBelow = block.top >= label.bottom - label.height * 0.5;
      if (!isBelow) continue;
      final sameColumn = (block.centerX - label.centerX).abs() <= label.width;
      if (!sameColumn) continue;
      final distance = block.top - label.bottom;
      if (distance < bestDistance) {
        bestDistance = distance;
        closest = block;
      }
    }
    return closest;
  }

  OcrBlock? _closestBlockOnSameLine(OcrResult ocr, OcrBlock label) {
    OcrBlock? closest;
    var bestDistance = double.infinity;
    for (final block in ocr.blocks) {
      if (identical(block, label)) continue;
      final sameLine = (block.centerY - label.centerY).abs() <= label.height;
      if (!sameLine) continue;
      final distance = (block.left - label.right).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        closest = block;
      }
    }
    return closest;
  }

  String? _firstPolicyToken(String text) {
    for (final match in _genericPolicyPattern.allMatches(text.toUpperCase())) {
      final value = match.group(1);
      if (value == null || !_isPlausiblePolicy(value) || !_hasDigit(value)) {
        continue;
      }
      if (_looksLikePhone(value) || _looksLikeDate(value)) continue;
      return value;
    }
    return null;
  }

  bool _isPlausiblePolicy(String value) =>
      value.length >= _minPolicyLength && value.length <= _maxPolicyLength;

  bool _hasDigit(String value) => RegExp(r'\d').hasMatch(value);

  // ── Dates ─────────────────────────────────────────────────────────────────

  _DatesResult _detectDates(OcrResult ocr, String normalizedText) {
    final dated = _extractDatesWithPositions(ocr);
    if (dated.isEmpty) {
      return const _DatesResult(
        null,
        null,
        OcrFieldConfidence.low,
        OcrFieldConfidence.low,
      );
    }

    final unique = <DateTime, _DatedToken>{};
    for (final token in dated) {
      unique.putIfAbsent(token.date, () => token);
    }
    final tokens = unique.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Try to associate dates with context labels.
    final startToken = _dateNearLabel(ocr, tokens, _startLabels);
    final expiryToken = _dateNearLabel(ocr, tokens, _expiryLabels);

    DateTime? start;
    DateTime? expiry;
    var labeled = false;

    if (startToken != null &&
        expiryToken != null &&
        startToken.date != expiryToken.date) {
      start = startToken.date;
      expiry = expiryToken.date;
      labeled = true;
    } else if (tokens.length >= 2) {
      // Fallback: smallest is start, largest is expiry.
      start = tokens.first.date;
      expiry = tokens.last.date;
    } else {
      return const _DatesResult(
        null,
        null,
        OcrFieldConfidence.low,
        OcrFieldConfidence.low,
      );
    }

    // Hard validation: SOAT lasts ~1 year (360–370 days). When two candidate
    // dates are present but the span is implausible, drop the dates and flag
    // the failure so telemetry can distinguish it from a generic miss.
    final spanDays = expiry.difference(start).inDays;
    if (spanDays < 360 || spanDays > 370) {
      return const _DatesResult(
        null,
        null,
        OcrFieldConfidence.low,
        OcrFieldConfidence.low,
        failedValidation: true,
      );
    }

    final confidence = labeled
        ? OcrFieldConfidence.high
        : OcrFieldConfidence.medium;
    return _DatesResult(start, expiry, confidence, confidence);
  }

  static const _startLabels = [
    'vigencia desde',
    'desde',
    'inicio',
    'expedicion',
  ];
  static const _expiryLabels = ['hasta', 'vence', 'vencimiento'];

  _DatedToken? _dateNearLabel(
    OcrResult ocr,
    List<_DatedToken> tokens,
    List<String> labels,
  ) {
    OcrBlock? labelBlock;
    for (final block in ocr.blocks) {
      final normalized = _normalize(block.text);
      if (labels.any(normalized.contains)) {
        labelBlock = block;
        break;
      }
    }
    if (labelBlock == null) return null;

    _DatedToken? closest;
    var bestDistance = double.infinity;
    for (final token in tokens) {
      final block = token.block;
      if (block == null) continue;
      final dx = block.centerX - labelBlock.centerX;
      final dy = block.centerY - labelBlock.centerY;
      final distance = dx * dx + dy * dy;
      if (distance < bestDistance) {
        bestDistance = distance;
        closest = token;
      }
    }
    return closest;
  }

  List<_DatedToken> _extractDatesWithPositions(OcrResult ocr) {
    final results = <_DatedToken>[];

    void scan(String text, OcrBlock? block) {
      for (final date in _parseDatesInText(text)) {
        results.add(_DatedToken(date, block));
      }
    }

    if (ocr.blocks.isEmpty) {
      scan(ocr.fullText, null);
    } else {
      for (final block in ocr.blocks) {
        scan(block.text, block);
      }
    }
    return results;
  }

  static final RegExp _numericDate = RegExp(
    r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})\b',
  );
  static final RegExp _isoDate = RegExp(
    r'\b(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\b',
  );
  static final RegExp _textualDate = RegExp(
    r'\b(\d{1,2})\s*(?:de\s+)?([a-záéíóú]{3,})\.?\s*(?:de\s+)?(\d{4})\b',
    caseSensitive: false,
  );

  List<DateTime> _parseDatesInText(String text) {
    final dates = <DateTime>[];

    for (final match in _isoDate.allMatches(text)) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final date = _safeDate(year, month, day);
      if (date != null) dates.add(date);
    }

    for (final match in _numericDate.allMatches(text)) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = _normalizeYear(int.parse(match.group(3)!));
      final date = _safeDate(year, month, day);
      if (date != null) dates.add(date);
    }

    for (final match in _textualDate.allMatches(text)) {
      final day = int.parse(match.group(1)!);
      final monthKey = _normalize(match.group(2)!).substring(0, 3);
      final month = _spanishMonths[monthKey];
      if (month == null) continue;
      final year = int.parse(match.group(3)!);
      final date = _safeDate(year, month, day);
      if (date != null) dates.add(date);
    }

    return dates;
  }

  int _normalizeYear(int year) => year < 100 ? 2000 + year : year;

  DateTime? _safeDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _normalize(String input) {
    final lower = input.toLowerCase();
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      buffer.write(accents[char] ?? char);
    }
    return buffer.toString();
  }
}

class _InsurerResult {
  const _InsurerResult(this.value, this.rule, this.confidence);
  final String? value;
  final SoatInsurerRule? rule;
  final OcrFieldConfidence confidence;
}

class _FieldResult<T> {
  const _FieldResult(this.value, this.confidence);
  final T? value;
  final OcrFieldConfidence confidence;
}

class _DatesResult {
  const _DatesResult(
    this.startDate,
    this.expiryDate,
    this.startConfidence,
    this.expiryConfidence, {
    this.failedValidation = false,
  });
  final DateTime? startDate;
  final DateTime? expiryDate;
  final OcrFieldConfidence startConfidence;
  final OcrFieldConfidence expiryConfidence;

  /// True when two candidate dates were found but failed the 360–370 day rule.
  final bool failedValidation;
}

class _DatedToken {
  const _DatedToken(this.date, this.block);
  final DateTime date;
  final OcrBlock? block;
}
