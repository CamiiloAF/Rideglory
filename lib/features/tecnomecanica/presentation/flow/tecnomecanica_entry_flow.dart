import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Punto de entrada estático para la RTM de un vehículo.
///
/// Navega a [TecnomecanicaStatusPage], que crea el cubit y gestiona
/// todos los estados (vacío → registrar, con datos → editar/borrar).
abstract final class TecnomecanicaEntryFlow {
  static Future<void> start(BuildContext context, VehicleModel vehicle) async {
    await context.push(AppRoutes.tecnomecanicaStatus, extra: vehicle);
  }
}
