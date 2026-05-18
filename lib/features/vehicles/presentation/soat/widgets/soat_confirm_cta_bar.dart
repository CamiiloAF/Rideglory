import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/presentation/soat/cubit/soat_form_cubit.dart';

class SoatConfirmCtaBar extends StatelessWidget {
  const SoatConfirmCtaBar({
    super.key,
    required this.vehicleId,
    required this.isManual,
    this.documentImage,
  });

  final String vehicleId;
  final bool isManual;
  final XFile? documentImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.darkBgPrimary,
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      child: BlocBuilder<SoatFormCubit, SoatFormState>(
        builder: (context, state) {
          final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);
          final cubit = context.read<SoatFormCubit>();
          final canSave = cubit.areDatesValid;
          return AppButton(
            label: isManual
                ? context.l10n.vehicle_soat_save_button
                : context.l10n.vehicle_soat_confirm_button,
            isLoading: isLoading,
            onPressed: canSave
                ? () => cubit.submit(vehicleId, documentImage: documentImage)
                : null,
          );
        },
      ),
    );
  }
}
