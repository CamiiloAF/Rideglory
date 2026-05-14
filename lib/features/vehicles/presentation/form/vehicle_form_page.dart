import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/image_storage_service.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';

import '../widgets/vehicle_form.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class VehicleFormPage extends StatelessWidget {
  final VehicleModel? vehicle;

  const VehicleFormPage({super.key, this.vehicle});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              FormImageCubit(getIt<ImageStorageService>())
                ..initialize(remoteImageUrl: vehicle?.imageUrl),
        ),
        BlocProvider(
          create: (context) =>
              getIt.get<VehicleFormCubit>()..initialize(vehicle: vehicle),
        ),
      ],
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
  late final Map<String, dynamic> _initialValues;
  late final bool _isEditing;

  @override
  void initState() {
    super.initState();
    final state = context.read<VehicleFormCubit>().state;
    _isEditing = state.isEditing;
    _initialValues = _buildInitialValues(state);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkArchivedVehicle();
    });
  }

  Future<void> _checkArchivedVehicle() async {
    final state = context.read<VehicleFormCubit>().state;
    if (state.isEditing && state.vehicle?.isArchived == true) {
      await ConfirmationDialog.show(
        context: context,
        title: context.l10n.vehicle_archivedVehicle,
        content: context.l10n.vehicle_archivedVehicleMessage,
        cancelLabel: context.l10n.cancel,
        confirmLabel: context.l10n.continue_,
        confirmType: DialogActionType.primary,
        dialogType: DialogType.confirmation,
        onCancel: (dialogContext) {
          context.pop();
          context.pop();
        },
      );
    }
  }

  Map<String, dynamic> _buildInitialValues(VehicleFormState state) {
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
    final imageCubit = context.read<FormImageCubit>();
    final vehicleToSave = cubit.buildVehicleToSave();

    if (vehicleToSave == null) {
      return;
    }

    cubit.saveVehicle(
      vehicleToSave,
      localImagePath: imageCubit.selectedLocalImagePath,
    );
  }

  void _listener(BuildContext context, VehicleFormState state) {
    state.vehicleResult.whenOrNull(
      data: (savedVehicle) {
        if (state.isEditing) {
          context.read<VehicleCubit>().applySavedVehicleEdit(savedVehicle);
        } else {
          context.read<VehicleCubit>().addVehicleLocally(savedVehicle);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.isEditing
                  ? context.l10n.updatedSuccessfully
                  : context.l10n.savedSuccessfully,
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(savedVehicle);
      },
      error: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: AppColors.error),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppAppBar(
        title: _isEditing
            ? context.l10n.vehicle_editVehicle
            : context.l10n.vehicle_addVehicle,
      ),
      body: BlocListener<VehicleFormCubit, VehicleFormState>(
        listener: _listener,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: VehicleForm(
            formKey: context.read<VehicleFormCubit>().formKey,
            initialValue: _initialValues,
            isEditing: _isEditing,
            onSave: _saveVehicle,
          ),
        ),
      ),
    );
  }
}
