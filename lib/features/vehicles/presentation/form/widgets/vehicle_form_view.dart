import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/services/image_storage_service.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/features/vehicles/domain/models/soat_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/form/vehicle_form_body.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_nav_header.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_confirmation_page.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';

class VehicleFormView extends StatefulWidget {
  const VehicleFormView({super.key});

  @override
  State<VehicleFormView> createState() => _VehicleFormViewState();
}

class _VehicleFormViewState extends State<VehicleFormView> {
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
            VehicleFormFields.currentMileage:
                state.vehicle!.currentMileage.toString(),
            VehicleFormFields.licensePlate: state.vehicle!.licensePlate,
            VehicleFormFields.vin: state.vehicle!.vin,
            VehicleFormFields.purchaseDate: state.vehicle!.purchaseDate,
            VehicleFormFields.color: state.vehicle!.color,
            VehicleFormFields.engine: state.vehicle!.engine,
            VehicleFormFields.horsepower: state.vehicle!.horsepower,
            VehicleFormFields.torque: state.vehicle!.torque,
            VehicleFormFields.weight: state.vehicle!.weight,
          }
        : <String, dynamic>{};
  }

  void _saveVehicle() {
    final cubit = context.read<VehicleFormCubit>();
    final imageCubit = context.read<FormImageCubit>();
    final vehicleToSave = cubit.buildVehicleToSave();

    if (vehicleToSave == null) return;

    cubit.saveVehicle(
      vehicleToSave,
      localImagePath: imageCubit.selectedLocalImagePath,
    );
  }

  Future<void> _confirmDelete() async {
    final state = context.read<VehicleFormCubit>().state;
    if (state.vehicle?.id == null) return;

    await ConfirmationDialog.show(
      context: context,
      title: context.l10n.vehicle_deleteVehicle,
      content: context.l10n.vehicle_deleteVehicleConfirmContent(
        state.vehicle!.name,
      ),
      cancelLabel: context.l10n.cancel,
      confirmLabel: context.l10n.delete,
      confirmType: DialogActionType.danger,
      dialogType: DialogType.confirmation,
      onConfirm: () {
        final vehicles = context.read<VehicleCubit>().availableVehicles;
        context.read<VehicleDeleteCubit>().deleteVehicle(
          state.vehicle!.id!,
          availableVehicles: vehicles,
        );
      },
    );
  }

  void _formListener(BuildContext context, VehicleFormState state) {
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

        // Caso 1: SOAT con imagen adjuntada — navegar a SoatConfirmationPage
        final soatPath = state.soatLocalPath;
        if (!state.isEditing && soatPath != null && savedVehicle.id != null) {
          if (!context.mounted) return;
          Navigator.of(context).pushReplacement( // Custom: pushReplacement — VehicleFormPage must not remain in back stack after SOAT confirmation.
            MaterialPageRoute<void>(
              builder: (_) => SoatConfirmationPage(
                vehicle: savedVehicle,
                documentImage: XFile(soatPath),
                isFromVehicleCreation: true,
              ),
            ),
          );
          return;
        }

        // Caso 2: SOAT manual capturado antes de crear el vehículo — guardarlo ahora
        final pendingManualSoat = state.pendingManualSoat;
        if (!state.isEditing &&
            pendingManualSoat != null &&
            savedVehicle.id != null) {
          _savePendingManualSoatAndPop(context, savedVehicle, pendingManualSoat);
          return;
        }

        context.pop(savedVehicle);
      },
      error: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  /// Guarda el SOAT manual pendiente en el backend y luego cierra el formulario.
  /// El vehículo ya fue creado exitosamente en este punto.
  Future<void> _savePendingManualSoatAndPop(
    BuildContext context,
    VehicleModel savedVehicle,
    PendingManualSoat pendingManualSoat,
  ) async {
    final vehicleId = savedVehicle.id!;
    final repository = getIt<VehicleRepository>();

    // Subir imagen adjunta si el usuario seleccionó una durante el formulario
    String? documentUrl;
    final localImagePath = pendingManualSoat.localImagePath;
    if (localImagePath != null) {
      final ext = localImagePath.split('.').last.toLowerCase();
      try {
        documentUrl = await getIt<ImageStorageService>().uploadImage(
          image: XFile(localImagePath),
          storagePath:
              'soat/$vehicleId/${DateTime.now().millisecondsSinceEpoch}.$ext',
        );
      } catch (_) {
        // La imagen falló pero el vehículo y el SOAT se guardan igual.
      }
    }

    final result = await repository.upsertSoat(
      vehicleId: vehicleId,
      soat: SoatModel(
        vehicleId: vehicleId,
        policyNumber: pendingManualSoat.policyNumber,
        insurer: pendingManualSoat.insurer,
        startDate: pendingManualSoat.startDate,
        expiryDate: pendingManualSoat.expiryDate,
        documentUrl: documentUrl,
      ),
    );

    if (!context.mounted) return;

    result.fold(
      (error) {
        // El vehículo se creó correctamente; solo falló el SOAT. Informar y continuar.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l10n.savedSuccessfully}. ${_soatErrorMsg(error)}',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      },
      (soat) {
        context.read<VehicleCubit>().updateSoatLocally(
          vehicleId,
          expiryDate: soat.expiryDate,
        );
      },
    );

    if (!context.mounted) return;
    context.pop(savedVehicle);
  }

  String _soatErrorMsg(DomainException error) =>
      'Error al guardar SOAT: ${error.message}';

  void _deleteListener(BuildContext context, VehicleDeleteState state) {
    state.when(
      initial: () {},
      loading: () {},
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.deletedSuccessfully),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      },
      error: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      errorLastVehicle: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleFormCubit, VehicleFormState>(
      builder: (context, formState) {
        return Scaffold(
          backgroundColor: AppColors.darkBgPrimary,
          appBar: VehicleFormNavHeader(
            isEditing: _isEditing,
            isLoading: formState.isLoading,
            onCancel: () => context.pop(),
            onSave: _saveVehicle,
          ),
          body: MultiBlocListener(
            listeners: [
              BlocListener<VehicleFormCubit, VehicleFormState>(
                listener: _formListener,
              ),
              BlocListener<VehicleDeleteCubit, VehicleDeleteState>(
                listener: _deleteListener,
              ),
            ],
            child: VehicleFormBody(
              formKey: context.read<VehicleFormCubit>().formKey,
              initialValue: _initialValues,
              onSave: _saveVehicle,
              onDelete: _confirmDelete,
            ),
          ),
        );
      },
    );
  }
}
