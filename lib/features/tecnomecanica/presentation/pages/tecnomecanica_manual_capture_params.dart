import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class TecnomecanicaManualCaptureParams {
  const TecnomecanicaManualCaptureParams({
    required this.cubit,
    this.vehicle,
    this.existingRtm,
    this.initialLocalImagePath,
  });

  final TecnomecanicaCubit cubit;
  final VehicleModel? vehicle;
  final TecnomecanicaModel? existingRtm;

  /// Ruta local de un archivo ya seleccionado antes de abrir el formulario.
  /// Se usa al editar datos pendientes en modo creación de vehículo.
  final String? initialLocalImagePath;
}
