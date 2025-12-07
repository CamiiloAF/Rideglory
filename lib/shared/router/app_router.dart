import 'package:go_router/go_router.dart';

import '../../features/maintenance/presentation/form/maintenance_form_page.dart';
import '../../features/maintenance/presentation/maintenances_page.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.maintenances,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.maintenances,
      name: AppRoutes.maintenances,
      builder: (context, state) {
        return const MaintenancesPage();
      },
    ),
    GoRoute(
      path: AppRoutes.createMaintenance,
      name: AppRoutes.createMaintenance,
      builder: (context, state) {
        return const MaintenanceFormPage();
      },
    ),
  ],
);
