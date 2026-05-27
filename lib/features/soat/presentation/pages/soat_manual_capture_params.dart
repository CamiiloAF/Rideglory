import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';

class SoatManualCaptureParams {
  const SoatManualCaptureParams({
    this.vehicle,
    this.soat,
    this.initialLocalImagePath,
  });

  final VehicleModel? vehicle;
  final SoatModel? soat;
  final String? initialLocalImagePath;
}
