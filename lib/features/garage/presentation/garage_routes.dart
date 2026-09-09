import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../domain/models/vehicle.dart';
import 'pages/brand_picker_page.dart';
import 'pages/vehicle_edit_page.dart';
import 'pages/vehicle_form_page.dart';

/// Rutas de garaje anidadas bajo `/garage`, registradas con una línea en
/// `app_router.dart`.
List<RouteBase> garageRoutes = [
  GoRoute(
    path: AppRoutes.vehicleAddPath,
    name: AppRoutes.vehicleAdd,
    builder: (context, state) => const VehicleFormPage(),
  ),
  GoRoute(
    path: AppRoutes.vehicleEditPath,
    name: AppRoutes.vehicleEdit,
    builder: (context, state) => VehicleEditPage(vehicle: state.extra! as Vehicle),
  ),
  GoRoute(
    path: AppRoutes.brandPickerPath,
    name: AppRoutes.brandPicker,
    builder: (context, state) => const BrandPickerPage(),
  ),
];
