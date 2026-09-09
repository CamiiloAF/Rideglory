import 'package:go_router/go_router.dart';

import '../domain/maintenance.dart';
import '../domain/vehicle_option.dart';
import 'pages/maintenance_detail_page.dart';
import 'pages/register_maintenance_page.dart';

/// Rutas de mantenimiento fuera del shell de pestañas: registrar/editar y
/// el detalle son pantallas completas, sin el Pill Tab Bar.
abstract final class MaintenanceRoutes {
  static const String register = 'maintenance-register';
  static const String registerPath = '/maintenance/register';

  static const String detail = 'maintenance-detail';
  static const String detailPath = '/maintenance/detail';
}

/// Argumentos de `/maintenance/register`: la moto de contexto y, si se
/// edita, el registro existente.
class RegisterMaintenanceArgs {
  const RegisterMaintenanceArgs({required this.vehicle, this.existing});

  final VehicleOption vehicle;
  final Maintenance? existing;
}

final List<RouteBase> maintenanceRoutes = [
  GoRoute(
    path: MaintenanceRoutes.registerPath,
    name: MaintenanceRoutes.register,
    builder: (context, state) {
      final args = state.extra! as RegisterMaintenanceArgs;
      return RegisterMaintenancePage(
        vehicle: args.vehicle,
        existing: args.existing,
      );
    },
  ),
  GoRoute(
    path: MaintenanceRoutes.detailPath,
    name: MaintenanceRoutes.detail,
    builder: (context, state) {
      final maintenance = state.extra! as Maintenance;
      return MaintenanceDetailPage(maintenance: maintenance);
    },
  ),
];
