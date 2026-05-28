import 'soat_extraction.dart';

/// Origin of the document being scanned (drives telemetry `had_pdf`).
enum SoatScanSource { camera, gallery, pdf }

/// Reason a scan did not yield prefillable data (telemetry `failure_reason`).
enum SoatScanFailureReason {
  noTextDetected,
  lowConfidence,
  validationFailed,
  permissionDenied,
  unknownError,
}

extension SoatScanFailureReasonX on SoatScanFailureReason {
  String get analyticsValue {
    switch (this) {
      case SoatScanFailureReason.noTextDetected:
        return 'no_text_detected';
      case SoatScanFailureReason.lowConfidence:
        return 'low_confidence';
      case SoatScanFailureReason.validationFailed:
        return 'validation_failed';
      case SoatScanFailureReason.permissionDenied:
        return 'permission_denied';
      case SoatScanFailureReason.unknownError:
        return 'unknown_error';
    }
  }
}

/// Raised by the scan use case when a document cannot be turned into a
/// prefillable [SoatExtraction]. Carries a machine-readable [reason] for both
/// telemetry and UI copy selection.
class SoatScanException implements Exception {
  const SoatScanException(this.reason);
  final SoatScanFailureReason reason;
}

/// Successful outcome of a scan: the parsed extraction. The caller decides,
/// via [SoatExtraction.shouldPrefill], whether to actually prefill.
class SoatScanResult {
  const SoatScanResult({required this.extraction});
  final SoatExtraction extraction;
}
