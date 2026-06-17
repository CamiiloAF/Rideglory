import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideglory/core/di/injection.dart';

import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/services/image_storage_service.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/constants/vehicle_form_fields.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_soat_form_data.dart';
import 'package:rideglory/features/vehicles/domain/repository/vehicle_repository.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/form/vehicle_form_body.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_capture_params.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/save_tecnomecanica_usecase.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

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
            VehicleFormFields.currentMileage: state.vehicle!.currentMileage
                .toString(),
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
      onConfirm: () {
        final vehicles = context.read<VehicleCubit>().availableVehicles;
        context.read<VehicleActionCubit>().deleteVehicle(
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

        // Caso 1: SOAT con imagen adjuntada — abrir el formulario unificado de
        // SOAT, reemplazando este form para no dejarlo en el back stack.
        final soatPath = state.soatLocalPath;
        if (!state.isEditing && soatPath != null && savedVehicle.id != null) {
          if (!context.mounted) return;
          context.pushReplacementNamed(
            AppRoutes.soatManualCapture,
            extra: SoatManualCaptureParams(
              vehicle: savedVehicle,
              initialLocalImagePath: soatPath,
            ),
          );
          return;
        }

        // Casos 2 y 3: SOAT manual y/o RTM pendientes — guardar ambos y luego pop.
        // El snackbar de éxito se muestra al terminar, no antes.
        final pendingManualSoat = state.pendingManualSoat;
        final pendingRtm = state.pendingRtm;
        if (!state.isEditing &&
            savedVehicle.id != null &&
            (pendingManualSoat != null || pendingRtm != null)) {
          _savePendingDocumentsAndPop(
            context,
            savedVehicle,
            successLabel: context.l10n.savedSuccessfully,
            pendingManualSoat: pendingManualSoat,
            pendingRtm: pendingRtm,
          );
          return;
        }

        // Sin documentos pendientes: navegar de inmediato con snackbar.
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
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  /// Guarda el SOAT y/o RTM pendientes en el backend y cierra el formulario.
  /// El vehículo ya fue creado exitosamente en este punto.
  Future<void> _savePendingDocumentsAndPop(
    BuildContext context,
    VehicleModel savedVehicle, {
    required String successLabel,
    PendingManualSoat? pendingManualSoat,
    PendingRtm? pendingRtm,
  }) async {
    final vehicleId = savedVehicle.id!;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final imageService = getIt<ImageStorageService>();
    final ts = DateTime.now().millisecondsSinceEpoch;

    // ── SOAT ────────────────────────────────────────────────────────────────
    if (pendingManualSoat != null) {
      String? soatDocUrl;
      final soatLocalPath = pendingManualSoat.localImagePath;
      if (soatLocalPath != null) {
        final ext = soatLocalPath.split('.').last.toLowerCase();
        try {
          soatDocUrl = await imageService.uploadImage(
            image: XFile(soatLocalPath),
            storagePath: 'soat/$vehicleId/${ts}_soat.$ext',
          );
        } catch (_) {}
      }

      final soatResult = await getIt<VehicleRepository>().upsertSoat(
        vehicleId: vehicleId,
        soat: VehicleSoatFormData(
          vehicleId: vehicleId,
          policyNumber: pendingManualSoat.policyNumber,
          insurer: pendingManualSoat.insurer,
          startDate: pendingManualSoat.startDate,
          expiryDate: pendingManualSoat.expiryDate,
          documentUrl: soatDocUrl,
        ),
      );

      if (context.mounted) {
        soatResult.fold(
          (error) => messenger.showSnackBar(
            SnackBar(
              content: Text('Error al guardar SOAT: ${error.message}'),
              backgroundColor: AppColors.warning,
            ),
          ),
          (soat) => context.read<VehicleCubit>().updateSoatLocally(
            vehicleId,
            expiryDate: soat.expiryDate,
          ),
        );
      }
    }

    // ── RTM ─────────────────────────────────────────────────────────────────
    if (pendingRtm != null) {
      final rtmLocalPath =
          pendingRtm.localImagePath ??
          (pendingRtm.documentUrl != null &&
                  !pendingRtm.documentUrl!.startsWith('http')
              ? pendingRtm.documentUrl
              : null);

      String? rtmDocUrl;
      if (rtmLocalPath != null) {
        final ext = rtmLocalPath.split('.').last.toLowerCase();
        try {
          rtmDocUrl = await imageService.uploadImage(
            image: XFile(rtmLocalPath),
            storagePath: 'tecnomecanica/$vehicleId/${ts}_rtm.$ext',
          );
        } catch (_) {}
      }

      final rtmResult = await getIt<SaveTecnomecanicaUseCase>()(
        vehicleId: vehicleId,
        tecnomecanica: TecnomecanicaModel(
          id: '',
          vehicleId: vehicleId,
          certificateNumber: pendingRtm.certificateNumber,
          cdaName: pendingRtm.cdaName,
          startDate: pendingRtm.startDate,
          expiryDate: pendingRtm.expiryDate,
          documentUrl: rtmDocUrl,
        ),
      );

      if (context.mounted) {
        rtmResult.fold(
          (error) => messenger.showSnackBar(
            SnackBar(
              content: Text('Error al guardar RTM: ${error.message}'),
              backgroundColor: AppColors.warning,
            ),
          ),
          (_) {},
        );
      }
    }

    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(successLabel),
          backgroundColor: AppColors.success,
        ),
      );
    }

    router.pop(savedVehicle);
  }

  void _deleteListener(BuildContext context, VehicleActionState state) {
    state.when(
      initial: () {},
      loading: () {},
      success: (deletedId) {
        context.read<VehicleCubit>().deleteVehicleLocally(deletedId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.deletedSuccessfully),
            backgroundColor: AppColors.success,
          ),
        );
        context.goAndClearStack(AppRoutes.garage);
      },
      archiveSuccess: (_) {},
      unarchiveSuccess: (_) {},
      error: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      },
      errorLastVehicle: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
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
          appBar: AppFormNavHeader(
            title: _isEditing
                ? context.l10n.vehicle_editVehicle
                : context.l10n.vehicle_addVehicle,
            leading: AppFormNavAction.text(
              label: context.l10n.cancel,
              onTap: () => context.pop(),
            ),
            trailing: AppFormNavAction.text(
              label: context.l10n.save,
              onTap: _saveVehicle,
              emphasized: true,
              isLoading: formState.isLoading,
            ),
          ),
          body: MultiBlocListener(
            listeners: [
              BlocListener<VehicleFormCubit, VehicleFormState>(
                listener: _formListener,
              ),
              BlocListener<VehicleActionCubit, VehicleActionState>(
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
