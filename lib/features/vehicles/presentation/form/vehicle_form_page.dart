import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_strings.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';

import '../widgets/vehicle_form.dart';
import 'package:rideglory/design_system/design_system.dart';

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
      await ConfirmationDialog.show(
        context: context,
        title: VehicleStrings.archivedVehicle,
        content: VehicleStrings.archivedVehicleMessage,
        cancelLabel: AppStrings.cancel,
        confirmLabel: AppStrings.continue_,
        confirmType: DialogActionType.primary,
        dialogType: DialogType.confirmation,
        onCancel: (dialogContext) {
          context.pop();
          context.pop();
        },
      );
    }
  }

  Map<String, dynamic> _getInitialValues() {
    final state = context.read<VehicleFormCubit>().state;

    return state.isEditing
        ? {
            VehicleFormFields.name: state.vehicle!.name,
            VehicleFormFields.brand: state.vehicle!.brand,
            VehicleFormFields.model: state.vehicle!.model,
            VehicleFormFields.year: state.vehicle!.year?.toString(),
            VehicleFormFields.currentMileage: state.vehicle!.currentMileage
                .toString(),
            VehicleFormFields.licensePlate: state.vehicle!.licensePlate,
            VehicleFormFields.vin: state.vehicle!.vin,
            VehicleFormFields.purchaseDate: state.vehicle!.purchaseDate,
          }
        : <String, dynamic>{};
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
        } else {
          context.read<VehicleCubit>().addVehicleLocally(savedVehicle);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.isEditing
                  ? AppStrings.updatedSuccessfully
                  : AppStrings.savedSuccessfully,
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(savedVehicle);
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

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppAppBar(
        title: isEditing
            ? VehicleStrings.editVehicle
            : VehicleStrings.addVehicle,
      ),
      body: BlocListener<VehicleFormCubit, VehicleFormState>(
        listener: _listener,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: VehicleForm(
            formKey: context.read<VehicleFormCubit>().formKey,
            initialValue: _getInitialValues(),
            isEditing: isEditing,
            onSave: _saveVehicle,
          ),
        ),
      ),
    );
  }
}
