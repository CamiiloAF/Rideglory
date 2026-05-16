import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/form/widgets/vehicle_form_section_header.dart';
import 'package:rideglory/features/vehicles/presentation/widgets/vehicle_document_upload_slot.dart';

class VehicleFormDocsSection extends StatelessWidget {
  const VehicleFormDocsSection({super.key});

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
            VehicleDocumentUploadSlot(
              title: context.l10n.vehicle_doc_soat_label,
              subtitle: context.l10n.vehicle_form_soat_subtitle,
              localPath: state.soatLocalPath,
              onUploadTap: () =>
                  context.read<VehicleFormCubit>().pickSoatDocument(),
              onClear: state.soatLocalPath != null
                  ? () =>
                      context.read<VehicleFormCubit>().clearSoatDocument()
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
