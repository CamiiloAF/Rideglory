import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';

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

    return state is VehicleFormEditing
        ? {
            'name': state.vehicle.name,
            'brand': state.vehicle.brand,
            'model': state.vehicle.model,
            'year': state.vehicle.year?.toString(),
            'currentMileage': state.vehicle.currentMileage.toString(),
            'distanceUnit': state.vehicle.distanceUnit,
            'licensePlate': state.vehicle.licensePlate,
            'vin': state.vehicle.vin,
            'purchaseDate': state.vehicle.purchaseDate,
          }
        : {'distanceUnit': 'KM'};
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
    final isEditing = state is VehicleFormEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<VehicleFormCubit, VehicleFormState>(
        listener: (context, state) {
          if (state is VehicleFormSuccess) {
            // Refresh the vehicle list
            context.read<VehicleListCubit>().loadVehicles();

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
            context.pop();
          } else if (state is VehicleFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is VehicleFormLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: VehicleForm(
                  key: context.read<VehicleFormCubit>().formKey,
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
