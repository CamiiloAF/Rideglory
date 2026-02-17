import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';

import '../widgets/vehicle_form.dart';

class VehicleFormPage extends StatelessWidget {
  final VehicleModel? vehicle;

  const VehicleFormPage({super.key, this.vehicle});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt.get<VehicleFormCubit>()..initialize(vehicle: vehicle),
      child: const _VehicleFormView(),
    );
  }
}

class _VehicleFormView extends StatefulWidget {
  const _VehicleFormView();

  @override
  State<_VehicleFormView> createState() => _VehicleFormViewState();
}

class _VehicleFormViewState extends State<_VehicleFormView> {
  Map<String, dynamic> _getInitialValues() {
    final state = context.read<VehicleFormCubit>().state;

    return state.isEditing
        ? {
            'name': state.vehicle!.name,
            'brand': state.vehicle!.brand,
            'model': state.vehicle!.model,
            'year': state.vehicle!.year?.toString(),
            'currentMileage': state.vehicle!.currentMileage.toString(),
            'distanceUnit': state.vehicle!.distanceUnit,
            'licensePlate': state.vehicle!.licensePlate,
            'vin': state.vehicle!.vin,
            'purchaseDate': state.vehicle!.purchaseDate,
          }
        : {'distanceUnit': DistanceUnit.kilometers};
  }

  void _saveVehicle() {
    final cubit = context.read<VehicleFormCubit>();
    final vehicleToSave = cubit.buildVehicleToSave();

    if (vehicleToSave == null) {
      return;
    }

    cubit.saveVehicle(vehicleToSave);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<VehicleFormCubit>().state;
    final isEditing = state.isEditing;

    return Scaffold(
      appBar: AppAppBar(title: isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
      body: BlocConsumer<VehicleFormCubit, VehicleFormState>(
        listenWhen: (previous, current) => true,
        listener: (context, state) {
          state.vehicleResult.whenOrNull(
            data: (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEditing
                        ? 'Vehicle updated successfully'
                        : 'Vehicle added successfully',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              context.pop(true);
            },
            error: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error.message),
                  backgroundColor: Colors.red,
                ),
              );
            },
          );
        },
        builder: (context, state) {
          final isLoading = state.isLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: VehicleForm(
                  formKey: context.read<VehicleFormCubit>().formKey,
                  initialValue: _getInitialValues(),
                  isEditing: isEditing,
                  onSave: _saveVehicle,
                  isLoading: isLoading,
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
