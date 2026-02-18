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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkArchivedVehicle();
    });
  }

  Future<void> _checkArchivedVehicle() async {
    final state = context.read<VehicleFormCubit>().state;
    if (state.isEditing && state.vehicle?.isArchived == true) {
      final shouldContinue = await _showArchivedVehicleDialog();
      if (!shouldContinue && mounted) {
        context.pop();
      }
    }
  }

  Future<bool> _showArchivedVehicleDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF6366F1),
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Vehículo Archivado',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Este vehículo está archivado. Si actualizas su información, el vehículo será desarchivado y volverá a estar disponible en tu lista de vehículos activos.',
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.unarchive_rounded,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¿Deseas continuar con la edición?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

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
