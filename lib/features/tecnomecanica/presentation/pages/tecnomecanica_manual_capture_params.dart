import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class TecnomecanicaManualCaptureParams {
  const TecnomecanicaManualCaptureParams({
    required this.cubit,
    this.vehicle,
    this.existingRtm,
  });

  final TecnomecanicaCubit cubit;
  final VehicleModel? vehicle;
  final TecnomecanicaModel? existingRtm;
}
