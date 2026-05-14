import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/presentation/cubit/soat_cubit.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_manual_form_view.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

class SoatManualFormPage extends StatelessWidget {
  const SoatManualFormPage({
    super.key,
    required this.vehicle,
    this.existingSoat,
  });

  final VehicleModel vehicle;
  final SoatModel? existingSoat;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SoatCubit>(),
      child: SoatManualFormView(vehicle: vehicle, existingSoat: existingSoat),
    );
  }
}
