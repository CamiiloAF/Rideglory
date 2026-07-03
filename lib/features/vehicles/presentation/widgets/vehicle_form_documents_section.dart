import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_document_upload_slot.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_form_add_more_doc_slot.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_form_section_label.dart';

class VehicleFormDocumentsSection extends StatelessWidget {
  const VehicleFormDocumentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleFormCubit, VehicleFormState>(
      builder: (context, state) {
        final docCount =
            (state.soatLocalPath != null ? 1 : 0) +
            (state.techReviewLocalPath != null ? 1 : 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                VehicleFormSectionLabel(context.l10n.vehicle_form_docs_section),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
                const Spacer(),
                Text(
                  '$docCount / 3',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnDarkSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            VehicleDocumentUploadSlot(
              title: context.l10n.vehicle_doc_soat_label,
              subtitle: context.l10n.vehicle_form_soat_subtitle,
              localPath: state.soatLocalPath,
              onUploadTap: () =>
                  context.read<VehicleFormCubit>().pickSoatDocument(),
              onClear: state.soatLocalPath != null
                  ? () => context.read<VehicleFormCubit>().clearSoatDocument()
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
