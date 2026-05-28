import '../../domain/models/soat_scan_result.dart';

/// Arguments for [SoatScanPage]: the local file to read and where it came from.
class SoatScanParams {
  const SoatScanParams({required this.filePath, required this.source});

  final String filePath;
  final SoatScanSource source;
}
