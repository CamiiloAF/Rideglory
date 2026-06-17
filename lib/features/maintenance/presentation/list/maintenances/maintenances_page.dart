import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenance_list_use_case.dart';
import 'package:rideglory/features/maintenance/presentation/delete/cubit/maintenance_delete_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/list/maintenances/widgets/maintenances_page_view.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

class MaintenancesPage extends StatelessWidget {
  final String? initialVehicleId;
  final bool readOnly;

  const MaintenancesPage({super.key, this.initialVehicleId, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    final vehicleCubit = context.read<VehicleCubit>();

    // When no specific vehicle is provided (entered from Profile),
    // default to the user's main vehicle so the list is never empty on open.
    final effectiveVehicleId =
        initialVehicleId ?? vehicleCubit.currentVehicle?.id;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final cubit = MaintenancesCubit(
              getIt<GetMaintenanceListUseCase>(),
              getIt<AnalyticsService>(),
            );
            if (effectiveVehicleId != null) {
              cubit.setInitialVehicleFilter(effectiveVehicleId);
              try {
                final vehicle = vehicleCubit.availableVehicles
                    .firstWhere((vehicle) => vehicle.id == effectiveVehicleId);
                cubit.setCurrentVehicleMileage(vehicle.currentMileage);
              } catch (_) {
                cubit.setCurrentVehicleMileage(vehicleCubit.currentMileage ?? 0);
              }
            } else {
              cubit.setCurrentVehicleMileage(vehicleCubit.currentMileage ?? 0);
            }
            cubit.fetchMaintenances();
            return cubit;
          },
        ),
        BlocProvider(create: (context) => getIt<MaintenanceDeleteCubit>()),
      ],
      // Show vehicle selector only when entered without a specific vehicle (from Profile).
      child: MaintenancesPageView(
        showVehicleSelector: initialVehicleId == null,
        readOnly: readOnly,
      ),
    );
  }
}
