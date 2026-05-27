import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_section_header.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_soat_form_slot.dart';
import 'package:rideglory/features/vehicles/presentation/soat/soat_manual_capture_page.dart';
import 'package:rideglory/features/vehicles/presentation/soat/widgets/vehicle_soat_options_sheet.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_document_upload_slot.dart';
import 'package:rideglory/shared/router/app_routes.dart';

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
            (soatCounted ? 1 : 0) +
            (state.techReviewLocalPath != null ? 1 : 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VehicleFormSectionHeader(
              title: context.l10n.vehicle_form_docs_section,
              badge: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                localPath: state.pendingManualSoat?.localImagePath ??
                    state.soatLocalPath,
                hasData: state.pendingManualSoat != null,
                dataLabel: context.l10n.vehicle_soat_data_added,
                onUploadTap: () => _onSoatTap(context, state.vehicle),
                onClear: (state.soatLocalPath != null ||
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
            VehicleDocumentUploadSlot(
              title: context.l10n.vehicle_doc_techreview_label,
              subtitle: context.l10n.vehicle_form_techreview_subtitle,
              localPath: state.techReviewLocalPath,
              onUploadTap: () =>
                  context.read<VehicleFormCubit>().pickTechReviewDocument(),
              onClear: state.techReviewLocalPath != null
                  ? () => context
                      .read<VehicleFormCubit>()
                      .clearTechReviewDocument()
                  : null,
            ),
            const SizedBox(height: 12),
            const _AddMoreDocSlot(),
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

Future<void> _onSoatTap(BuildContext context, VehicleModel? vehicle) async {
  // --- Vehículo nuevo (sin ID): mostrar opciones antes de crearlo ---
  if (vehicle?.id == null) {
    final result = await showModalBottomSheet<SoatOptionsResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const VehicleSoatOptionsSheet(),
    );

    if (!context.mounted) return;

    // Ambos flujos (subir archivo y entrada manual) terminan en el formulario
    // de captura manual. En el caso de upload, la imagen ya seleccionada se
    // pasa como initialLocalImagePath para que aparezca pre-cargada.
    final String? preselectedPath =
        result is SoatOptionsUpload ? result.image.path : null;

    if (result is SoatOptionsUpload || result is SoatOptionsManual) {
      if (!context.mounted) return;
      final pendingData = await Navigator.of(context).push<PendingManualSoat>(
        MaterialPageRoute<PendingManualSoat>(
          builder: (_) => SoatManualCapturePage(
            initialLocalImagePath: preselectedPath,
          ),
        ),
      );
      if (pendingData != null && context.mounted) {
        context.read<VehicleFormCubit>().storePendingManualSoat(pendingData);
      }
    }
    return;
  }

  // --- Vehículo existente: ir al detalle si ya tiene SOAT, al upload si no ---
  final hasSoat = vehicle!.soatStatus != null &&
      vehicle.soatStatus != SoatStatus.noSoat;

  if (hasSoat) {
    context.pushNamed(AppRoutes.soatStatus, extra: vehicle);
  } else {
    context.pushNamed(AppRoutes.vehicleSoat, extra: vehicle);
  }
}

class _AddMoreDocSlot extends StatelessWidget {
  const _AddMoreDocSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorderPrimary),
            ),
            child: const Icon(
              Icons.add,
              size: 20,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.vehicle_form_add_doc_title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textOnDarkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.vehicle_form_add_doc_subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textOnDarkTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textOnDarkTertiary,
          ),
        ],
      ),
    );
  }
}
