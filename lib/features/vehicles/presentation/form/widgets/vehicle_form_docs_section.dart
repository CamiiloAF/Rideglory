import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_add_more_doc_slot.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_section_header.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart';
import 'package:rideglory/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_params.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_rtm_form_slot.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_soat_form_slot.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/presentation/pages/soat_manual_capture_params.dart';
import 'package:rideglory/features/soat/presentation/scan/soat_entry_flow.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_document_upload_slot.dart';

class VehicleFormDocsSection extends StatelessWidget {
  const VehicleFormDocsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleFormCubit, VehicleFormState>(
      builder: (context, state) {
        // En modo edición contamos el SOAT existente si el vehículo ya lo tiene.
        final isEditing = state.vehicle?.id != null;
        final soatCounted = isEditing
            ? (state.vehicle!.soatStatus != null &&
                  state.vehicle!.soatStatus != SoatStatus.noSoat)
            : state.soatLocalPath != null || state.pendingManualSoat != null;
        final docCount =
            (soatCounted ? 1 : 0) + (state.techReviewLocalPath != null ? 1 : 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VehicleFormSectionHeader(
              title: context.l10n.vehicle_form_docs_section,
              badge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.darkTertiary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Opcional',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textOnDarkTertiary,
                  ),
                ),
              ),
              trailing: Text(
                '$docCount / 3',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Modo edición: muestra estado real del SOAT cargado desde la API.
            // Modo creación: muestra el slot de subida local estándar.
            if (isEditing)
              VehicleSoatFormSlot(vehicle: state.vehicle!)
            else
              VehicleDocumentUploadSlot(
                title: context.l10n.vehicle_doc_soat_label,
                subtitle: context.l10n.vehicle_form_soat_subtitle,
                localPath: null,
                hasData: state.soatLocalPath != null ||
                    state.pendingManualSoat != null,
                dataLabel: context.l10n.vehicle_soat_data_added,
                onUploadTap: () => _onSoatTap(context, state.vehicle),
                onTap: (state.soatLocalPath != null ||
                        state.pendingManualSoat != null)
                    ? () => _onSoatEditCreationTap(
                        context,
                        pendingManualSoat: state.pendingManualSoat,
                        soatLocalPath: state.soatLocalPath,
                      )
                    : null,
                onClear:
                    (state.soatLocalPath != null ||
                        state.pendingManualSoat != null)
                    ? () {
                        context.read<VehicleFormCubit>().clearSoatDocument();
                        context
                            .read<VehicleFormCubit>()
                            .clearPendingManualSoat();
                      }
                    : null,
              ),
            const SizedBox(height: 12),
            if (isEditing)
              VehicleRtmFormSlot(vehicle: state.vehicle!)
            else
              VehicleDocumentUploadSlot(
                title: context.l10n.vehicle_doc_techreview_label,
                subtitle: context.l10n.vehicle_form_techreview_subtitle,
                localPath: null,
                hasData: state.pendingRtm != null,
                dataLabel: context.l10n.vehicle_rtm_data_added,
                onUploadTap: () => _onRtmCreationTap(context),
                onTap: state.pendingRtm != null
                    ? () => _onRtmCreationTap(
                        context,
                        pendingRtm: state.pendingRtm,
                      )
                    : null,
                onClear: state.pendingRtm != null
                    ? () => context.read<VehicleFormCubit>().clearPendingRtm()
                    : null,
              ),
            const SizedBox(height: 12),
            const VehicleFormAddMoreDocSlot(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: AppColors.textOnDarkTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.vehicle_form_docs_max_hint,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textOnDarkTertiary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Abre el formulario de captura SOAT directamente en modo edición de pendiente,
/// pre-llenando los campos con [pendingManualSoat] si ya existe.
/// Solo se usa en modo creación de vehículo (vehicle sin id).
Future<void> _onSoatEditCreationTap(
  BuildContext context, {
  required PendingManualSoat? pendingManualSoat,
  required String? soatLocalPath,
}) async {
  final cubit = context.read<VehicleFormCubit>();

  SoatModel? prefill;
  if (pendingManualSoat != null) {
    prefill = SoatModel(
      id: '',
      vehicleId: '',
      policyNumber: pendingManualSoat.policyNumber,
      insurer: pendingManualSoat.insurer,
      startDate: pendingManualSoat.startDate,
      expiryDate: pendingManualSoat.expiryDate,
    );
  }

  final pendingData = await context.push<PendingManualSoat>(
    AppRoutes.soatManualCapture,
    extra: SoatManualCaptureParams(
      soat: prefill,
      // Pasamos la imagen siempre; si hay prefill, SoatManualCapturePage
      // omite el re-escaneo automático.
      initialLocalImagePath: pendingManualSoat?.localImagePath ?? soatLocalPath,
    ),
  );
  if (pendingData != null && context.mounted) {
    cubit.storePendingManualSoat(pendingData);
  }
}

Future<void> _onSoatTap(BuildContext context, VehicleModel? vehicle) async {
  // --- Vehículo nuevo (sin ID): mostrar opciones antes de crearlo ---
  if (vehicle?.id == null) {
    await SoatEntryFlow.start(
      context,
      formCubit: context.read<VehicleFormCubit>(),
    );
    return;
  }

  // --- Vehículo existente: ir al detalle si ya tiene SOAT, al flujo si no ---
  final hasSoat =
      vehicle!.soatStatus != null && vehicle.soatStatus != SoatStatus.noSoat;

  if (hasSoat) {
    context.pushNamed(AppRoutes.soatStatus, extra: vehicle);
  } else {
    await SoatEntryFlow.start(context, vehicle: vehicle);
  }
}

Future<void> _onRtmCreationTap(
  BuildContext context, {
  PendingRtm? pendingRtm,
}) async {
  final cubit = getIt<TecnomecanicaCubit>();

  TecnomecanicaModel? prefill;
  String? initialLocalImagePath;
  if (pendingRtm != null) {
    // documentUrl en modo creación almacena la ruta local, no una URL remota.
    final isLocalPath = pendingRtm.documentUrl != null &&
        !pendingRtm.documentUrl!.startsWith('http');
    initialLocalImagePath = isLocalPath ? pendingRtm.documentUrl : null;
    prefill = TecnomecanicaModel(
      id: '',
      vehicleId: '',
      cdaName: pendingRtm.cdaName,
      startDate: pendingRtm.startDate,
      expiryDate: pendingRtm.expiryDate,
      documentUrl: isLocalPath ? null : pendingRtm.documentUrl,
    );
  }

  final result = await context.push<TecnomecanicaModel>(
    AppRoutes.tecnomecanicaManualCapture,
    extra: TecnomecanicaManualCaptureParams(
      cubit: cubit,
      existingRtm: prefill,
      initialLocalImagePath: initialLocalImagePath,
    ),
  );
  if (result != null && context.mounted) {
    context.read<VehicleFormCubit>().storePendingRtm(
      PendingRtm(
        cdaName: result.cdaName,
        startDate: result.startDate,
        expiryDate: result.expiryDate,
        documentUrl: result.documentUrl,
      ),
    );
  }
}
