import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_cubit.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_status_view.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class SoatStatusPage extends StatelessWidget {
  const SoatStatusPage({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SoatCubit>()..load(vehicle.id ?? ''),
      child: SoatStatusView(vehicle: vehicle),
    );
  }
}
