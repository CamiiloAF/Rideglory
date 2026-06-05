import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/tecnomecanica/presentation/widgets/tecnomecanica_status_view.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class TecnomecanicaStatusPage extends StatelessWidget {
  const TecnomecanicaStatusPage({super.key, required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TecnomecanicaCubit>()..load(vehicle.id ?? ''),
      child: TecnomecanicaStatusView(vehicle: vehicle),
    );
  }
}
