import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
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
            'vehicleType': state.vehicle!.vehicleType,
            'licensePlate': state.vehicle!.licensePlate,
            'vin': state.vehicle!.vin,
            'purchaseDate': state.vehicle!.purchaseDate,
          }
        : {
            'distanceUnit': DistanceUnit.kilometers,
            'vehicleType': VehicleType.motorcycle,
          };
  }

  void _saveVehicle() {
    final cubit = context.read<VehicleFormCubit>();
    final vehicleToSave = cubit.buildVehicleToSave();

    if (vehicleToSave == null) {
      return;
    }

    cubit.saveVehicle(vehicleToSave);
  }

  void _listener(BuildContext context, VehicleFormState state) {
    state.vehicleResult.whenOrNull(
      data: (savedVehicle) {
        // Update the current vehicle in VehicleCubit if it was edited
        if (state.isEditing) {
          context.read<VehicleCubit>().updateCurrentVehicleIfMatch(
            savedVehicle,
          );
        }

        // Set as current vehicle if checkbox was checked
        final formData = context
            .read<VehicleFormCubit>()
            .formKey
            .currentState
            ?.value;
        final setAsCurrent = formData?['setAsCurrent'] as bool? ?? false;

        if (setAsCurrent && savedVehicle.id != null) {
          context.read<VehicleCubit>().updateCurrentVehicleIfMatch(
            savedVehicle,
            shouldUpdateMainVehicle: true,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.isEditing
                  ? 'Vehículo actualizado exitosamente'
                  : 'Vehículo agregado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      },
      error: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<VehicleFormCubit>().state;
    final isEditing = state.isEditing;

    final mainVehicle = context.select(
      (VehicleCubit cubit) => cubit.currentVehicle,
    );

    return Scaffold(
      appBar: AppAppBar(
        title: isEditing ? 'Editar Vehículo' : 'Agregar Vehículo',
      ),
      body: BlocConsumer<VehicleFormCubit, VehicleFormState>(
        listener: _listener,
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
                  isMainVehicle: mainVehicle == state.vehicle,
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
