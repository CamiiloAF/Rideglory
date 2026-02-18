import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_form_view.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class MaintenanceFormPage extends StatelessWidget {
  final MaintenanceModel? maintenance;
  final VehicleModel? preselectedVehicle;

  const MaintenanceFormPage({
    super.key,
    this.maintenance,
    this.preselectedVehicle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MaintenanceFormCubit>()
        ..initialize(
          maintenance: maintenance,
          preselectedVehicle: preselectedVehicle,
        ),
      child: const MaintenanceFormView(),
    );
  }
}
