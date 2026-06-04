import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class TecnomecanicaManualCaptureParams {
  const TecnomecanicaManualCaptureParams({
    this.vehicle,
    this.existingRtm,
  });

  final VehicleModel? vehicle;
  final TecnomecanicaModel? existingRtm;
}
