import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../design_system/components/app_banner.dart';
import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/saving_button.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/models/vehicle.dart';
import '../cubit/vehicle_form_cubit.dart';
import '../cubit/vehicle_form_state.dart';

/// Botón de guardar con sus tres estados: reposo, guardando (`SavingButton`)
/// y error accionable (banner + reintentar).
///
/// Pencil: e0fmR, M2i66X, sH7QQ
class VehicleFormSubmitButton extends StatelessWidget {
  const VehicleFormSubmitButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VehicleFormCubit>();
    return BlocBuilder<VehicleFormCubit, VehicleFormState>(
      builder: (context, state) {
        final canSubmit = state.canSubmitDetails;
        final label = cubit.isEditing
            ? context.l10n.garage_save_changes_button
            : context.l10n.garage_save_vehicle_button;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.submission is Error<Vehicle>) ...[
              AppBanner(
                title: context.l10n.garage_save_error_title,
                body: context.l10n.garage_save_error_body,
              ),
              const SizedBox(height: 12),
            ],
            if (state.submission is Loading<Vehicle>)
              SavingButton(label: context.l10n.garage_saving_label)
            else
              AppPrimaryButton(
                label: label,
                onPressed: canSubmit ? cubit.submit : null,
              ),
          ],
        );
      },
    );
  }
}
