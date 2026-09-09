import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../domain/maintenance.dart';
import '../../domain/vehicle_option.dart';
import '../cubit/register_maintenance_cubit.dart';
import 'register_maintenance_view.dart';

/// Registrar (o editar) un mantenimiento en 3 pasos.
class RegisterMaintenancePage extends StatelessWidget {
  const RegisterMaintenancePage({
    required this.vehicle,
    this.existing,
    super.key,
  });

  final VehicleOption vehicle;
  final Maintenance? existing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<RegisterMaintenanceCubit>()..start(vehicle, existing: existing),
      child: const RegisterMaintenanceView(),
    );
  }
}
