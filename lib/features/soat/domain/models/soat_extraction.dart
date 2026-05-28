import 'package:flutter/foundation.dart';

/// Confidence level of a single extracted SOAT field.
enum OcrFieldConfidence {
  /// Extracted with an explicit context label and validation passed.
  high,

  /// Extracted by regex but without a nearby context label.
  medium,

  /// Could not be extracted with enough certainty (field not prefilled).
  low,
}

/// Pure-Dart result of parsing recognized SOAT text into the four target
/// fields, each with its own confidence so the UI can decide what to prefill
/// and how to flag it.
@immutable
class SoatExtraction {
  const SoatExtraction({
    this.policyNumber,
    this.startDate,
    this.expiryDate,
    this.insurer,
    this.policyNumberConfidence = OcrFieldConfidence.low,
    this.startDateConfidence = OcrFieldConfidence.low,
    this.expiryDateConfidence = OcrFieldConfidence.low,
    this.insurerConfidence = OcrFieldConfidence.low,
    this.datesFailedValidation = false,
  });

  const SoatExtraction.empty()
    : policyNumber = null,
      startDate = null,
      expiryDate = null,
      insurer = null,
      policyNumberConfidence = OcrFieldConfidence.low,
      startDateConfidence = OcrFieldConfidence.low,
      expiryDateConfidence = OcrFieldConfidence.low,
      insurerConfidence = OcrFieldConfidence.low,
      datesFailedValidation = false;

  final String? policyNumber;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final String? insurer;

  final OcrFieldConfidence policyNumberConfidence;
  final OcrFieldConfidence startDateConfidence;
  final OcrFieldConfidence expiryDateConfidence;
  final OcrFieldConfidence insurerConfidence;

  /// True when the parser found two candidate dates but they failed the hard
  /// 360–370 day SOAT-span validation, so the dates were dropped rather than
  /// prefilled. Lets the scan use case distinguish "inconsistent dates" from
  /// generic low confidence for telemetry (PRD §5).
  final bool datesFailedValidation;

  List<OcrFieldConfidence> get _confidences => [
    policyNumberConfidence,
    startDateConfidence,
    expiryDateConfidence,
    insurerConfidence,
  ];

  /// Count of fields extracted with [OcrFieldConfidence.high].
  int get highConfidenceCount =>
      _confidences.where((c) => c == OcrFieldConfidence.high).length;

  /// Count of fields that carry a non-null value (regardless of confidence).
  int get extractedFieldsCount => [
    policyNumber,
    startDate,
    expiryDate,
    insurer,
  ].where((value) => value != null).length;

  /// Whether any field was extracted with medium confidence (UI shows a
  /// "review carefully" hint).
  bool get hasMediumConfidence =>
      _confidences.any((c) => c == OcrFieldConfidence.medium);

  /// Global rule (PRD §3.5): prefill only when at least 2 fields are high
  /// confidence. Otherwise fall back silently to the manual flow.
  bool get shouldPrefill => highConfidenceCount >= 2;

  /// Whether a given field should be flagged as auto-filled in the UI.
  bool isFieldAutofilled(SoatField field) {
    switch (field) {
      case SoatField.policyNumber:
        return policyNumber != null &&
            policyNumberConfidence != OcrFieldConfidence.low;
      case SoatField.startDate:
        return startDate != null &&
            startDateConfidence != OcrFieldConfidence.low;
      case SoatField.expiryDate:
        return expiryDate != null &&
            expiryDateConfidence != OcrFieldConfidence.low;
      case SoatField.insurer:
        return insurer != null && insurerConfidence != OcrFieldConfidence.low;
    }
  }

  OcrFieldConfidence confidenceOf(SoatField field) {
    switch (field) {
      case SoatField.policyNumber:
        return policyNumberConfidence;
      case SoatField.startDate:
        return startDateConfidence;
      case SoatField.expiryDate:
        return expiryDateConfidence;
      case SoatField.insurer:
        return insurerConfidence;
    }
  }

  SoatExtraction copyWith({
    String? policyNumber,
    DateTime? startDate,
    DateTime? expiryDate,
    String? insurer,
    OcrFieldConfidence? policyNumberConfidence,
    OcrFieldConfidence? startDateConfidence,
    OcrFieldConfidence? expiryDateConfidence,
    OcrFieldConfidence? insurerConfidence,
    bool? datesFailedValidation,
  }) {
    return SoatExtraction(
      policyNumber: policyNumber ?? this.policyNumber,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      insurer: insurer ?? this.insurer,
      policyNumberConfidence:
          policyNumberConfidence ?? this.policyNumberConfidence,
      startDateConfidence: startDateConfidence ?? this.startDateConfidence,
      expiryDateConfidence: expiryDateConfidence ?? this.expiryDateConfidence,
      insurerConfidence: insurerConfidence ?? this.insurerConfidence,
      datesFailedValidation:
          datesFailedValidation ?? this.datesFailedValidation,
    );
  }
}

enum SoatField { policyNumber, startDate, expiryDate, insurer }
