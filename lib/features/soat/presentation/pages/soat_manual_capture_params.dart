import 'package:rideglory/features/soat/domain/models/soat_extraction.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';

class SoatManualCaptureParams {
  const SoatManualCaptureParams({
    this.vehicle,
    this.soat,
    this.initialLocalImagePath,
    this.extraction,
  });

  final VehicleModel? vehicle;
  final SoatModel? soat;
  final String? initialLocalImagePath;

  /// Optional OCR result used to prefill the form and flag auto-filled fields.
  final SoatExtraction? extraction;
}
