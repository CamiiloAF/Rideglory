import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_capture_params.dart';
import 'package:rideglory/features/soat/presentation/widgets/soat_vehicle_options_sheet.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Punto de entrada unificado para agregar un SOAT.
///
/// Muestra el [SoatVehicleOptionsSheet] (subir documento o ingresar manual) y,
/// según el resultado, navega a [AppRoutes.soatManualCapture]. Reemplaza la
/// antigua pantalla `SoatUploadPage`.
///
/// - **Vehículo existente** ([vehicle] con `id`): modo edición. El formulario
///   guarda en el backend y retorna `true`; el llamador refresca con [onSaved].
/// - **Vehículo nuevo** ([vehicle] `null` o sin `id`): el formulario retorna un
///   [PendingManualSoat] que se almacena vía [VehicleFormCubit].
abstract final class SoatEntryFlow {
  static Future<void> start(
    BuildContext context, {
    VehicleModel? vehicle,
    VoidCallback? onSaved,
    VehicleFormCubit? formCubit,
  }) async {
    final result = await showModalBottomSheet<SoatOptionsResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SoatVehicleOptionsSheet(),
    );

    if (result == null || !context.mounted) return;
    if (result is! SoatOptionsUpload && result is! SoatOptionsManual) return;

    final String? preselectedPath = result is SoatOptionsUpload
        ? result.image.path
        : null;

    final isExisting = vehicle?.id != null;

    if (isExisting) {
      final saved = await context.push<bool>(
        AppRoutes.soatManualCapture,
        extra: SoatManualCaptureParams(
          vehicle: vehicle,
          initialLocalImagePath: preselectedPath,
        ),
      );
      if (saved == true) onSaved?.call();
      return;
    }

    final pendingData = await context.push<PendingManualSoat>(
      AppRoutes.soatManualCapture,
      extra: SoatManualCaptureParams(initialLocalImagePath: preselectedPath),
    );
    if (pendingData != null && formCubit != null) {
      formCubit.storePendingManualSoat(pendingData);
    }
  }
}
