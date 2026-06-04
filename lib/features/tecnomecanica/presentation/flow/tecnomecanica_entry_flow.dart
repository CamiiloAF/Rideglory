import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_params.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Punto de entrada estático para agregar o editar una RTM.
///
/// Sin bottom sheet, sin OCR. Navega directamente a [TecnomecanicaManualCapturePage].
abstract final class TecnomecanicaEntryFlow {
  static Future<void> start(
    BuildContext context,
    VehicleModel vehicle, {
    VoidCallback? onSaved,
  }) async {
    final saved = await context.push<bool>(
      AppRoutes.tecnomecanicaManualCapture,
      extra: TecnomecanicaManualCaptureParams(vehicle: vehicle),
    );
    if (saved == true) onSaved?.call();
  }
}
